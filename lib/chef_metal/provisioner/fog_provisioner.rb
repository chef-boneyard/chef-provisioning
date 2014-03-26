require 'chef_metal/provisioner'
require 'chef_metal/aws_credentials'

module ChefMetal
  class Provisioner

    # Provisions machines in vagrant.
    class FogProvisioner < Provisioner

      include Chef::Mixin::ShellOut

      DEFAULT_OPTIONS = {
        :create_timeout => 600,
        :start_timeout => 600,
        :ssh_timeout => 20
      }

      # Create a new vagrant provisioner.
      #
      # ## Parameters
      # compute_options - hash of options to be passed to Fog::Compute.new
      # Special options:
      #   - :base_bootstrap_options is merged with bootstrap_options in acquire_machine
      #     to present the full set of bootstrap options.  Write down any bootstrap_options
      #     you intend to apply universally here.
      #   - :aws_credentials is an AWS CSV file (created with Download Credentials)
      #     containing your aws key information.  If you do not specify aws_access_key_id
      #     and aws_secret_access_key explicitly, the first line from this file
      #     will be used.  You may pass a Cheffish::AWSCredentials object.
      #   - :create_timeout - the time to wait for the instance to boot to ssh (defaults to 600)
      #   - :start_timeout - the time to wait for the instance to start (defaults to 600)
      #   - :ssh_timeout - the time to wait for ssh to be available if the instance is detected as up (defaults to 20)
      def initialize(compute_options)
        @base_bootstrap_options = compute_options.delete(:base_bootstrap_options) || {}
        if compute_options[:provider] == 'AWS'
          aws_credentials = compute_options.delete(:aws_credentials)
          if aws_credentials
            @aws_credentials = aws_credentials
          else
            @aws_credentials = ChefMetal::AWSCredentials.new
            @aws_credentials.load_default
          end
          compute_options[:aws_access_key_id] ||= @aws_credentials.default[:access_key_id]
          compute_options[:aws_secret_access_key] ||= @aws_credentials.default[:secret_access_key]
        end
        @key_pairs = {}
        @compute_options = compute_options
        @base_bootstrap_options_for = {}
      end

      attr_reader :compute_options
      attr_reader :aws_credentials
      attr_reader :key_pairs

      def current_base_bootstrap_options
        result = @base_bootstrap_options.dup
        if key_pairs.size > 0
          last_pair_name = key_pairs.keys.last
          last_pair = key_pairs[last_pair_name]
          result[:key_name] ||= last_pair_name
          result[:private_key_path] ||= last_pair.private_key_path
          result[:public_key_path] ||= last_pair.public_key_path
        end
        result
      end

      # Acquire a machine, generally by provisioning it.  Returns a Machine
      # object pointing at the machine, allowing useful actions like setup,
      # converge, execute, file and directory.  The Machine object will have a
      # "node" property which must be saved to the server (if it is any
      # different from the original node object).
      #
      # ## Parameters
      # provider - the provider object that is calling this method.
      # node - node object (deserialized json) representing this machine.  If
      #        the node has a provisioner_options hash in it, these will be used
      #        instead of options provided by the provisioner.  TODO compare and
      #        fail if different?
      #        node will have node['normal']['provisioner_options'] in it with any options.
      #        It is a hash with this format:
      #
      #           -- provisioner_url: fog:<relevant_fog_options>
      #           -- bootstrap_options: hash of options to pass to compute.servers.create
      #           -- is_windows: true if windows.  TODO detect this from ami?
      #           -- create_timeout - the time to wait for the instance to boot to ssh (defaults to 600)
      #           -- start_timeout - the time to wait for the instance to start (defaults to 600)
      #           -- ssh_timeout - the time to wait for ssh to be available if the instance is detected as up (defaults to 20)
      #
      #        Example bootstrap_options for ec2:
      #           :image_id =>'ami-311f2b45',
      #           :flavor_id =>'t1.micro',
      #           :key_name => 'key-pair-name'
      #
      #        node['normal']['provisioner_output'] will be populated with information
      #        about the created machine.  For vagrant, it is a hash with this
      #        format:
      #
      #           -- provisioner_url: fog:<relevant_fog_options>
      #           -- server_id: the ID of the server so it can be found again
      #
      def acquire_machine(provider, node)
        # Set up the modified node data
        provisioner_options = node['normal']['provisioner_options'] || {}
        provisioner_output = node['normal']['provisioner_output'] || {
          'provisioner_url' => provisioner_url
        }

        if provisioner_output['provisioner_url'] != provisioner_url
          raise "Switching providers for a machine is not currently supported!  Use machine :destroy and then re-create the machine on the new provider."
        end

        node['normal']['provisioner_output'] = provisioner_output

        if provisioner_output['server_id']

          # If the server already exists, make sure it is up

          # TODO verify that the server info matches the specification (ami, etc.)\
          server = server_for(node)
          if !server
            Chef::Log.warn "Machine #{node['name']} (#{provisioner_output['server_id']} on #{provisioner_url}) is not associated with the ec2 account.  Recreating ..."
            need_to_create = true
          elsif %w(terminated archive).include?(server.state) # Can't come back from that
            Chef::Log.warn "Machine #{node['name']} (#{server.id} on #{provisioner_url}) is terminated.  Recreating ..."
            need_to_create = true
          else
            need_to_create = false
            if !server.ready?
              provider.converge_by "start machine #{node['name']} (#{server.id} on #{provisioner_url})" do
                server.start
              end
              provider.converge_by "wait for machine #{node['name']} (#{server.id} on #{provisioner_url}) to be ready" do
                wait_until_ready(server, option_for(node, :start_timeout))
              end
            else
              wait_until_ready(server, option_for(node, :ssh_timeout))
            end
          end
        else
          need_to_create = true
        end

        if need_to_create
          # If the server does not exist, create it
          bootstrap_options = bootstrap_options_for(provider.new_resource, node)

          start_time = Time.now
          timeout = option_for(node, :create_timeout)

          description = [ "create machine #{node['name']} on #{provisioner_url}" ]
          bootstrap_options.each_pair { |key,value| description << "    #{key}: #{value.inspect}" }
          server = nil
          provider.converge_by description do
            server = compute.servers.create(bootstrap_options)
            provisioner_output['server_id'] = server.id
            # Save quickly in case something goes wrong
            save_node(provider, node, provider.new_resource.chef_server)
          end

          if server
            # Re-retrieve the server in a more malleable form and wait for it to be ready
            server = compute.servers.get(server.id)
            provider.converge_by "machine #{node['name']} created as #{server.id} on #{provisioner_url}" do
            end
            # Wait for the machine to come up and for ssh to start listening
            transport = nil
            _self = self
            provider.converge_by "wait for machine #{node['name']} to boot" do
              server.wait_for(timeout - (Time.now - start_time)) do
                if ready?
                  transport ||= _self.transport_for(server)
                  begin
                    transport.execute('pwd')
                    true
                  rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
                    false
                  rescue
                    true
                  end
                else
                  false
                end
              end
            end

            # If there is some other error, we just wait patiently for SSH
            begin
              server.wait_for(option_for(node, :ssh_timeout)) { transport.available? }
            rescue Fog::Errors::TimeoutError
              # Sometimes (on EC2) the machine comes up but gets stuck or has
              # some other problem.  If this is the case, we restart the server
              # to unstick it.  Reboot covers a multitude of sins.
              Chef::Log.warn "Machine #{node['name']} (#{server.id} on #{provisioner_url}) was started but SSH did not come up.  Rebooting machine in an attempt to unstick it ..."
              provider.converge_by "reboot machine #{node['name']} to try to unstick it" do
                server.reboot
              end
              provider.converge_by "wait for machine #{node['name']} to be ready after reboot" do
                wait_until_ready(server, option_for(node, :start_timeout))
              end
            end
          end
        end

        # Create machine object for callers to use
        machine_for(node, server)
      end

      # Connect to machine without acquiring it
      def connect_to_machine(node)
        machine_for(node)
      end

      def delete_machine(provider, node)
        if node['normal']['provisioner_output'] && node['normal']['provisioner_output']['server_id']
          server = compute.servers.get(node['normal']['provisioner_output']['server_id'])
          provider.converge_by "destroy machine #{node['name']} (#{node['normal']['provisioner_output']['server_id']} at #{provisioner_url})" do
            server.destroy
          end
          convergence_strategy_for(node).delete_chef_objects(provider, node)
        end
      end

      def stop_machine(provider, node)
        # If the machine doesn't exist, we silently do nothing
        if node['normal']['provisioner_output'] && node['normal']['provisioner_output']['server_id']
          server = compute.servers.get(node['normal']['provisioner_output']['server_id'])
          provider.converge_by "stop machine #{node['name']} (#{server.id} at #{provisioner_url}" do
            server.stop
          end
        end
      end

      def resource_created(machine)
        @base_bootstrap_options_for[machine] = current_base_bootstrap_options
      end


      def compute
        @compute ||= begin
          require 'fog/compute'
          require 'fog'
          Fog::Compute.new(compute_options)
        end
      end

      def provisioner_url
        provider_identifier = case compute_options[:provider]
          when 'AWS'
            compute_options[:aws_access_key_id]
          when 'DigitalOcean'
            compute_options[:digitalocean_client_id]
          else
            '???'
        end
        "fog:#{compute_options[:provider]}:#{provider_identifier}"
      end

      # Not meant to be part of public interface
      def transport_for(server)
        # TODO winrm
        create_ssh_transport(server)
      end

      protected

      def option_for(node, key)
        if node['normal']['provisioner_options'] && node['normal']['provisioner_options'][key.to_s]
          node['normal']['provisioner_options'][key.to_s]
        elsif compute_options[key]
          compute_options[key]
        else
          DEFAULT_OPTIONS[key]
        end
      end

      def symbolize_keys(options)
        options.inject({}) { |result,(key,value)| result[key.to_sym] = value; result }
      end

      def server_for(node)
        if node['normal']['provisioner_output'] && node['normal']['provisioner_output']['server_id']
          compute.servers.get(node['normal']['provisioner_output']['server_id'])
        else
          nil
        end
      end

      def bootstrap_options_for(machine, node)
        provisioner_options = node['normal']['provisioner_options'] || {}
        bootstrap_options = @base_bootstrap_options_for[machine] || current_base_bootstrap_options
        bootstrap_options = bootstrap_options.merge(symbolize_keys(provisioner_options['bootstrap_options'] || {}))
        require 'socket'
        require 'etc'
        tags = {
            'Name' => node['name'],
            'BootstrapChefServer' => machine.chef_server[:chef_server_url],
            'BootstrapHost' => Socket.gethostname,
            'BootstrapUser' => Etc.getlogin,
            'BootstrapNodeName' => node['name']
        }
        if machine.chef_server[:options] && machine.chef_server[:options][:data_store]
          tags['ChefLocalRepository'] = machine.chef_server[:options][:data_store].chef_fs.fs_description
        end
        # User-defined tags override the ones we set
        tags.merge!(bootstrap_options[:tags]) if bootstrap_options[:tags]
        bootstrap_options.merge!({ :tags => tags })

        # Provide reasonable defaults for DigitalOcean
        if compute_options[:provider] == 'DigitalOcean'
          if !bootstrap_options[:image_id]
            bootstrap_options[:image_name] ||= 'CentOS 6.4 x32'
            bootstrap_options[:image_id] = compute.images.select { |image| image.name == bootstrap_options[:image_name] }.first.id
          end
          if !bootstrap_options[:flavor_id]
            bootstrap_options[:flavor_name] ||= '512MB'
            bootstrap_options[:flavor_id] = compute.flavors.select { |flavor| flavor.name == bootstrap_options[:flavor_name] }.first.id
          end
          if !bootstrap_options[:region_id]
            bootstrap_options[:region_name] ||= 'San Francisco 1'
            bootstrap_options[:region_id] = compute.regions.select { |region| region.name == bootstrap_options[:region_name] }.first.id
          end
          bootstrap_options[:ssh_key_ids] ||= [ compute.ssh_keys.select { |k| k.name == bootstrap_options[:key_name] }.first.id ]

          # You don't get to specify name yourself
          bootstrap_options[:name] = node['name']
        end

        bootstrap_options
      end

      def machine_for(node, server = nil)
        server ||= server_for(node)
        if !server
          raise "Server for node #{node['name']} has not been created!"
        end

        if node['normal']['provisioner_options'] && node['normal']['provisioner_options']['is_windows']
          require 'chef_metal/machine/windows_machine'
          ChefMetal::Machine::WindowsMachine.new(node, transport_for(server), convergence_strategy_for(node))
        else
          require 'chef_metal/machine/unix_machine'
          ChefMetal::Machine::UnixMachine.new(node, transport_for(server), convergence_strategy_for(node))
        end
      end

      def convergence_strategy_for(node)
        if node['normal']['provisioner_options'] && node['normal']['provisioner_options']['is_windows']
          @windows_convergence_strategy ||= begin
            require 'chef_metal/convergence_strategy/install_msi'
            ChefMetal::ConvergenceStrategy::InstallMsi.new
          end
        else
          @unix_convergence_strategy ||= begin
            require 'chef_metal/convergence_strategy/install_cached'
            ChefMetal::ConvergenceStrategy::InstallCached.new
          end
        end
      end

      def ssh_options_for(server)
        result = {
# TODO create a user known hosts file
#          :user_known_hosts_file => vagrant_ssh_config['UserKnownHostsFile'],
#          :paranoid => true,
          :auth_methods => [ 'publickey' ],
          :keys_only => true,
          :host_key_alias => "#{server.id}.#{compute_options[:provider]}"
        }
        if server.respond_to?(:private_key) && server.private_key
          result[:keys] = [ server.private_key ]
        elsif server.respond_to?(:key_name) && key_pairs[server.key_name]
          # TODO generalize for others?
          result[:keys] ||= [ key_pairs[server.key_name].private_key_path ]
        else
          # TODO need a way to know which key if there were multiple
          result[:keys] = [ key_pairs.first[1].private_key_path ]
        end
        result
      end

      def create_ssh_transport(server)
        require 'chef_metal/transport/ssh'

        ssh_options = ssh_options_for(server)
        # If we're on AWS, the default is to use ubuntu, not root
        if compute_options[:provider] == 'AWS'
          username = compute_options[:ssh_username] || 'ubuntu'
        else
          username = compute_options[:ssh_username] || 'root'
        end
        options = {}
        if compute_options[:sudo] || (!compute_options.has_key?(:sudo) && username != 'root')
          options[:prefix] = 'sudo '
        end
        remote_host = nil
        if compute_options[:use_private_ip_for_ssh]
          remote_host = server.private_ip_address
        else
          remote_host = server.public_ip_address
        end

        ChefMetal::Transport::SSH.new(remote_host, username, ssh_options, options)
      end

      def wait_until_ready(server, timeout)
        transport = nil
        _self = self
        server.wait_for(timeout) do
          if transport
            transport.available?
          elsif ready?
            # Don't create the transport until the machine is ready (we won't have the host till then)
            transport = _self.transport_for(server)
            transport.available?
          else
            false
          end
        end
      end
    end
  end
end
