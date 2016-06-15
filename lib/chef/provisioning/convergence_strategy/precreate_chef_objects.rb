require 'chef/provisioning/convergence_strategy'
require 'pathname'
require 'cheffish'
require 'chef_zero/socketless_server_map'
require_relative 'ignore_convergence_failure'

class Chef
module Provisioning
  class ConvergenceStrategy
    class PrecreateChefObjects < ConvergenceStrategy

      def initialize(convergence_options, config)
        super
        if convergence_options[:ignore_failure]
          extend IgnoreConvergenceFailure
        end
      end

      def chef_server
        @chef_server ||= convergence_options[:chef_server] || Cheffish.default_chef_server(config)
      end

      def setup_convergence(action_handler, machine)
        # Create keys on machine
        private_key, public_key = create_keys(action_handler, machine)
        # Create node and client on chef server
        create_chef_objects(action_handler, machine, private_key, public_key)

        # If the chef server lives on localhost, tunnel the port through to the guest
        # (we need to know what got tunneled!)
        chef_server_url = chef_server[:chef_server_url]
        chef_server_url = machine.make_url_available_to_remote(chef_server_url)

        # Support for multiple ohai hints, required on some platforms
        create_ohai_files(action_handler, machine)

        # Create client.rb and client.pem on machine
        content = client_rb_content(chef_server_url, machine.node['name'])
        machine.write_file(action_handler, convergence_options[:client_rb_path], content, :ensure_dir => true)
      end

      def converge(action_handler, machine)
        machine.make_url_available_to_remote(chef_server[:chef_server_url])
      end

      def cleanup_convergence(action_handler, machine_spec)
        _self = self
        Chef::Provisioning.inline_resource(action_handler) do
          chef_node machine_spec.name do
            chef_server _self.chef_server
            action :delete
          end
          chef_client machine_spec.name do
            chef_server _self.chef_server
            action :delete
          end
        end
      end

      protected

      def create_keys(action_handler, machine)
        server_private_key = machine.read_file(convergence_options[:client_pem_path])
        if server_private_key
          begin
            server_private_key, format = Cheffish::KeyFormatter.decode(server_private_key)
          rescue
            server_private_key = nil
          end
        end

        if server_private_key
          if source_key && server_private_key.to_pem != source_key.to_pem
            # If the server private key does not match our source key, overwrite it
            server_private_key = source_key
            if convergence_options[:allow_overwrite_keys]
              machine.write_file(action_handler, convergence_options[:client_pem_path], server_private_key.to_pem, :ensure_dir => true)
            else
              raise "Private key on machine #{machine.name} does not match desired input key."
            end
          end

        else

          # If the server does not already have keys, create them and upload
          _convergence_options = convergence_options
          Chef::Provisioning.inline_resource(action_handler) do
            private_key 'in_memory' do
              path :none
              if _convergence_options[:private_key_options]
                _convergence_options[:private_key_options].each_pair do |key,value|
                  send(key, value)
                end
              end
              after { |resource, private_key| server_private_key = private_key }
            end
          end

          machine.write_file(action_handler, convergence_options[:client_pem_path], server_private_key.to_pem, :ensure_dir => true)
        end

        # We shouldn't be returning this: see https://github.com/chef/chef-provisioning/issues/292
        [ server_private_key, server_private_key.public_key ]
      end

      def is_localhost(host)
        host == '127.0.0.1' || host == 'localhost' || host == '[::1]'
      end

      def source_key
        if convergence_options[:source_key].is_a?(String)
          key, format = Cheffish::KeyFormatter.decode(convergence_options[:source_key], convergence_options[:source_key_pass_phrase])
          key
        elsif convergence_options[:source_key]
          convergence_options[:source_key]
        elsif convergence_options[:source_key_path]
          key, format = Cheffish::KeyFormatter.decode(IO.read(convergence_options[:source_key_path]), convergence_options[:source_key_pass_phrase], convergence_options[:source_key_path])
          key
        else
          nil
        end
      end

      # Create the ohai file(s)
      def create_ohai_files(action_handler, machine)
        if convergence_options[:ohai_hints]
          convergence_options[:ohai_hints].each_pair do |hint, data|
            # The location of the ohai hint
            ohai_hint = "/etc/chef/ohai/hints/#{hint}.json"
            # It's in a different path on windows
            if machine.machine_spec.reference['is_windows']
              ohai_hint = [machine.system_drive, ohai_hint.split('/')[2..-1]].join('\\')
            end
            machine.write_file(action_handler, ohai_hint, data.to_json, :ensure_dir => true)
          end
        end
      end

      def create_chef_objects(action_handler, machine, private_key, public_key)
        _convergence_options = convergence_options
        _chef_server = chef_server
        _format =  _convergence_options[:public_key_format]
        # Save the node and create the client keys and client.
        Chef::Provisioning.inline_resource(action_handler) do
          # Create client
          chef_client machine.name do
            chef_server _chef_server
            source_key public_key
            output_key_path _convergence_options[:public_key_path]
            output_key_format _format if _format
            admin _convergence_options[:admin]
            validator _convergence_options[:validator]
          end

          # Create node
          # TODO strip automatic attributes first so we don't race with "current state"
          chef_node machine.name do
            chef_server _chef_server
            raw_json machine.node
          end
        end

        # If using enterprise/hosted chef, fix acls
        if chef_server[:chef_server_url] =~ /\/+organizations\/.+/
          grant_client_node_permissions(action_handler, chef_server, machine, ["read", "update"], private_key)
        end
      end

      # Grant the client permissions to the node
      # This procedure assumes that the client name and node name are the same
      def grant_client_node_permissions(action_handler, chef_server, machine, perms, private_key)
        node_name = machine.name
        api = Cheffish.chef_server_api(chef_server)
        node_perms = api.get("/nodes/#{node_name}/_acl")

        begin
          perms.each do |p|
            if !node_perms[p]['actors'].include?(node_name)
              action_handler.perform_action "Add #{node_name} to client #{p} ACLs" do
                node_perms[p]['actors'] << node_name
                api.put("/nodes/#{node_name}/_acl/#{p}", p => node_perms[p])
              end
            end
          end
        rescue Net::HTTPServerException => e
          if e.response.code == "400"
            action_handler.perform_action "Delete #{node_name} and recreate as client #{node_name}" do
              api.delete("/nodes/#{node_name}")
              as_user = chef_server.dup
              as_user[:options] = as_user[:options].merge(
                client_name: node_name,
                signing_key_filename: nil,
                raw_key: private_key.to_pem
              )
              as_user_api = Cheffish.chef_server_api(as_user)
              as_user_api.post("/nodes", machine.node)
            end
          else
            raise
          end
        end
      end

      def client_rb_content(chef_server_url, node_name)
        # Chef stores a 'port registry' of chef zero URLs.  If we set the remote host's
        # chef_server_url to a `chefzero` url it will fail because it does not know
        # about the workstation's chef zero server
        uri = URI.parse(chef_server_url)
        if uri.scheme == 'chefzero' && uri.host == 'localhost'
          if !Chef::Config[:listen]
            raise "The remote host is configured to access the local chefzero host, but " +
              "the local chefzero host is not configured to listen.  Provide --listen or " +
              "set `listen true` in the chef config."
          end
          # Once chef and chef-dk are using chef-zero which supports this, we can
          # remove the else block and the if check
          if ChefZero::SocketlessServerMap.respond_to?(:server_on_port)
            chef_server_url = ChefZero::SocketlessServerMap.server_on_port(uri.port).url
          else
            chef_server_url = chef_server_url.gsub(/^chefzero/, 'http')
          end
        end

        ssl_verify_mode = convergence_options[:ssl_verify_mode]
        ssl_verify_mode ||= if chef_server_url.downcase.start_with?("https")
                              :verify_peer
                            else
                              :verify_none
                            end

        content = <<-EOM
          chef_server_url #{chef_server_url.inspect}
          node_name #{node_name.inspect}
          client_key #{convergence_options[:client_pem_path].inspect}
          ssl_verify_mode #{ssl_verify_mode.to_sym.inspect}
        EOM
        if convergence_options[:bootstrap_proxy]
          content << <<-EOM
            http_proxy #{convergence_options[:bootstrap_proxy].inspect}
            https_proxy #{convergence_options[:bootstrap_proxy].inspect}
          EOM
        end
        if convergence_options[:bootstrap_no_proxy]
          content << <<-EOM
            no_proxy #{convergence_options[:bootstrap_no_proxy].inspect}
          EOM
        end
        content.gsub!(/^\s+/, "")
        content << convergence_options[:chef_config] if convergence_options[:chef_config]
        content
      end
    end
  end
end
end
