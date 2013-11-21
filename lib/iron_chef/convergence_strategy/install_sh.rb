require 'iron_chef/convergence_strategy'

module IronChef
  class ConvergenceStrategy
    class InstallSh < ConvergenceStrategy
      @@install_sh_cache = {}

      def initialize(options = {})
        @install_sh_url = options[:install_sh_url] || 'http://www.opscode.com/chef/install.sh'
        @install_sh_path = options[:install_sh_path] || '/tmp/chef-install.sh'
        @client_rb_path = options[:client_rb_path] || '/etc/chef/client.rb'
        @client_pem_path = options[:client_pem_path] || '/etc/chef/client.pem'
      end

      attr_reader :install_sh_url
      attr_reader :install_sh_path
      attr_reader :client_rb_path
      attr_reader :client_pem_path

      def setup_convergence(provider, machine, machine_resource)
        # Create node and client on chef server
        private_key = create_chef_objects(provider, machine, machine_resource)

        # Create client.rb and client.pem on machine
        machine.write_file(provider, client_pem_path, private_key)
        machine.write_file(provider, client_rb_path, client_rb_content(machine))

        # Install chef-client.  TODO check and update version if not latest / not desired?
        if machine.execute_always('chef-client -v').exitstatus != 0
          # TODO ssh verification of install.sh before running arbtrary code would be nice?
          @@install_sh_cache[install_sh_url] ||= Net::HTTP.get(URI(install_sh_url))
          machine.write_file(provider, install_sh_path, @@install_sh_cache[install_sh_url])
          machine.execute(provider, "bash #{install_sh_path}")
        end
      end

      def converge(provider, machine)
        machine.execute(provider, 'chef-client')
      end

      def delete_chef_objects(provider, node)
        IronChef.inline_resource(provider) do
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
        IronChef.inline_resource(provider) do
          chef_node machine.node['name'] do
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
        IronChef.inline_resource(provider) do
          chef_client machine.node['name'] do
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

      def client_rb_content(machine)
        <<EOM
node_name #{machine.node['name']}
client_key #{client_pem_path}
EOM
      end
    end
  end
end
