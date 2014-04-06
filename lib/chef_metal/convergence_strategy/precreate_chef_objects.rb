require 'chef_metal/convergence_strategy'
require 'pathname'
require 'cheffish'

module ChefMetal
  class ConvergenceStrategy
    class PrecreateChefObjects < ConvergenceStrategy
      def initialize(options = {})
        super
        @client_rb_path = options[:client_rb_path]
        @client_pem_path = options[:client_pem_path]
      end

      attr_reader :client_rb_path
      attr_reader :client_pem_path

      def setup_convergence(action_handler, machine, machine_resource)
        # Create keys on machine
        public_key = create_keys(action_handler, machine, machine_resource)
        # Create node and client on chef server
        create_chef_objects(action_handler, machine, machine_resource, public_key)

        # If the chef server lives on localhost, tunnel the port through to the guest
        chef_server_url = machine_resource.chef_server[:chef_server_url]
        chef_server_url = machine.make_url_available_to_remote(chef_server_url)

        # Create client.rb and client.pem on machine
        content = client_rb_content(chef_server_url, machine.node['name'])
        machine.write_file(action_handler, client_rb_path, content, :ensure_dir => true)
      end

      def cleanup_convergence(action_handler, node)
        ChefMetal.inline_resource(action_handler) do
          chef_node node['name'] do
            action :delete
          end
          chef_client node['name'] do
            action :delete
          end
        end
      end

      protected

      def create_keys(action_handler, machine, machine_resource)
        server_private_key = machine.read_file(client_pem_path)
        if server_private_key
          begin
            server_private_key, format = Cheffish::KeyFormatter.decode(server_private_key)
          rescue
            server_private_key = nil
          end
        end

        if server_private_key
          source_key = source_key_for(machine_resource)
          if source_key && server_private_key.to_pem != source_key.to_pem
            # If the server private key does not match our source key, overwrite it
            server_private_key = source_key
            if machine_resource.allow_overwrite_keys
              machine.write_file(action_handler, client_pem_path, server_private_key.to_pem, :ensure_dir => true)
            else
              raise "Private key on machine #{machine_resource.name} does not match desired input key."
            end
          end

        else

          # If the server does not already have keys, create them and upload
          Cheffish.inline_resource(action_handler) do
            private_key 'in_memory' do
              path :none
              if machine_resource.private_key_options
                machine_resource.private_key_options.each_pair do |key,value|
                  send(key, value)
                end
              end
              after { |resource, private_key| server_private_key = private_key }
            end
          end

          machine.write_file(action_handler, client_pem_path, server_private_key.to_pem, :ensure_dir => true)
        end

        server_private_key.public_key
      end

      def is_localhost(host)
        host == '127.0.0.1' || host == 'localhost' || host == '[::1]'
      end

      def source_key_for(machine_resource)
        if machine_resource.source_key.is_a?(String)
          key, format = Cheffish::KeyFormatter.decode(machine_resource.source_key, machine_resource.source_key_pass_phrase)
          key
        elsif machine_resource.source_key
          machine_resource.source_key
        elsif machine_resource.source_key_path
          key, format = Cheffish::KeyFormatter.decode(IO.read(machine_resource.source_key_path), machine_resource.source_key_pass_phrase, machine_resource.source_key_path)
          key
        else
          nil
        end
      end

      def create_chef_objects(action_handler, machine, machine_resource, public_key)
        # Save the node and create the client keys and client.
        ChefMetal.inline_resource(action_handler) do
          # Create client
          chef_client machine.node['name'] do
            chef_server machine_resource.chef_server
            source_key public_key
            output_key_path machine_resource.public_key_path
            output_key_format machine_resource.public_key_format
            admin machine_resource.admin
            validator machine_resource.validator
          end

          # Create node
          # TODO strip automatic attributes first so we don't race with "current state"
          chef_node machine.node['name'] do
            chef_server machine_resource.chef_server
            raw_json machine.node
          end
        end

        # If using enterprise/hosted chef, fix acls
        if machine_resource.chef_server[:chef_server_url] =~ /\/+organizations\/.+/
          grant_client_node_permissions(machine_resource.chef_server, machine.node['name'], ["read", "update"])
        end
      end

      # Grant the client permissions to the node
      # This procedure assumes that the client name and node name are the same
      def grant_client_node_permissions(chef_server, node_name, perms)
        rest = Chef::REST.new(chef_server[:chef_server_url])
        node_perms = rest.get("/nodes/#{node_name}/_acl")
        perms.each do |p|
          node_perms[p]['actors'] << node_name unless node_perms[p]['actors'].include?(node_name)
          rest.put("/nodes/#{node_name}/_acl/#{p}", p => node_perms[p])
        end
      end

      def client_rb_content(chef_server_url, node_name)
        <<EOM
chef_server_url #{chef_server_url.inspect}
node_name #{node_name.inspect}
client_key #{client_pem_path.inspect}
EOM
      end
    end
  end
end
