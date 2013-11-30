require 'chef_metal/convergence_strategy'
require 'pathname'

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

      def setup_convergence(provider, machine, machine_resource)
        # Create node and client on chef server
        private_key = create_chef_objects(provider, machine, machine_resource)

        # If the chef server lives on localhost, tunnel the port through to the guest
        chef_server_url = machine_resource.chef_server[:chef_server_url]
        url = URI(chef_server_url)
        # TODO IPv6
        if url.host == "127.0.0.1"
          machine.forward_remote_port_to_local(url.port, url.port)
        end

        # Create client.rb and client.pem on machine
        machine.write_file(provider, client_pem_path, private_key, :ensure_dir => true)
        content = client_rb_content(chef_server_url, machine.node['name'])
        machine.write_file(provider, client_rb_path, content, :ensure_dir => true)
      end

      def delete_chef_objects(provider, node)
        ChefMetal.inline_resource(provider) do
          chef_node node['name'] do
            action :delete
          end
          chef_client node['name'] do
            action :delete
          end
        end
      end

      protected

      def create_chef_objects(provider, machine, machine_resource)
        # Save the node and create the client.  TODO strip automatic attributes first so we don't race with "current state"
        ChefMetal.inline_resource(provider) do
          chef_node machine.node['name'] do
            chef_server machine_resource.chef_server
            raw_json machine.node
          end
        end

        desired_private_key = machine.read_file(client_pem_path)
        # Verify private key can be parsed
        begin
          OpenSSL::PKey.read(desired_private_key)
        rescue
          desired_private_key = nil
        end

        # Create or update the client
        final_private_key = nil
        ChefMetal.inline_resource(provider) do
          chef_client machine.node['name'] do
            chef_server machine_resource.chef_server
            public_key_path machine_resource.public_key_path
            private_key_path machine_resource.private_key_path
            private_key desired_private_key
            admin machine_resource.admin
            validator machine_resource.validator
            key_owner true
            if desired_private_key
              action :create
            else
              action :regenerate_keys
            end
            
            # Capture the private key for upload
            after { |resource, json, private_key, public_key| final_private_key = private_key.to_pem }
          end
        end
        final_private_key
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
