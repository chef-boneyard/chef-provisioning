require 'chef_metal/driver'
require 'chef_metal/aws_credentials'
require 'chef_metal/openstack_credentials'
require 'chef_metal/machine/windows_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/machine_spec'
require 'chef_metal/convergence_strategy/install_msi'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/transport/ssh'
require 'chef_metal_fog/version'
require 'fog'
require 'fog/core'
require 'fog/compute'
require 'fog/aws'
require 'socket'
require 'etc'
require 'time'

module ChefMetalFog
  # Provisions machines in vagrant.
  class FogDriver < ChefMetal::Driver

    include Chef::Mixin::ShellOut

    DEFAULT_OPTIONS = {
      :create_timeout => 600,
      :start_timeout => 600,
      :ssh_timeout => 20
    }

    def self.from_url(driver_url)
      scheme, driver, id = driver_url.split(':', 3)
      FogDriver.new({ :provider => driver }, id)
    end

    # Create a new fog driver.
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
    # id - the ID in the driver_url (fog:PROVIDER:ID)
    def initialize(compute_options, id=nil)
      @compute_options = compute_options
      @base_bootstrap_options = compute_options.delete(:base_bootstrap_options) || {}

      case compute_options[:provider]
      when 'AWS'
        aws_credentials = compute_options.delete(:aws_credentials)
        if aws_credentials
          @aws_credentials = aws_credentials
        else
          @aws_credentials = ChefMetal::AWSCredentials.new
          @aws_credentials.load_default
        end
        compute_options[:aws_access_key_id] ||= @aws_credentials.default[:access_key_id]
        compute_options[:aws_secret_access_key] ||= @aws_credentials.default[:secret_access_key]
        # TODO actually find a key with the proper id
        # TODO let the user specify credentials and driver profiles that we can use
        if id && aws_login_info[0] != id
          raise "Default AWS credentials point at AWS account #{aws_login_info[0]}, but inflating from URL #{id}"
        end
      when 'OpenStack'
        openstack_credentials = compute_options.delete(:openstack_credentials)
        if openstack_credentials
          @openstack_credentials = openstack_credentials
        else
          @openstack_credentials = ChefMetal::OpenstackCredentials.new
          @openstack_credentials.load_default
        end

        compute_options[:openstack_username] ||= @openstack_credentials.default[:openstack_username]
        compute_options[:openstack_api_key] ||= @openstack_credentials.default[:openstack_api_key]
        compute_options[:openstack_auth_url] ||= @openstack_credentials.default[:openstack_auth_url]
        compute_options[:openstack_tenant] ||= @openstack_credentials.default[:openstack_tenant]
      end
      @base_bootstrap_options_for = {}
    end

    attr_reader :compute_options
    attr_reader :aws_credentials
    attr_reader :openstack_credentials

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
    # converge, execute, file and directory.
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a action_handler, but could be anything that can support the
    #        ChefMetal::ActionHandler interface (i.e., in the case of the test
    #        kitchen metal driver for acquiring and destroying VMs; see the base
    #        class for what needs providing).
    # machine_spec - object representing the node and the machine's current
    #                location (if any). Location has this format:
    #                - driver_url: fog:<driver>:<unique_account_info>
    #                - server_id: the ID of the server so it can be found again
    # machine_options - options for creating this machine. Has these values:
    #
    #           -- driver_url: fog:<relevant_fog_options>
    #           -- bootstrap_options: hash of options to pass to compute.servers.create
    #           -- is_windows: true if windows.  TODO detect this from ami?
    #           -- create_timeout - the time to wait for the instance to boot to ssh (defaults to 600)
    #           -- start_timeout - the time to wait for the instance to start (defaults to 600)
    #           -- ssh_timeout - the time to wait for ssh to be available if the instance is detected as up (defaults to 20)
    #
    #        Example bootstrap_options for ec2:
    #          'bootstrap_options' => {
    #            'image_id' =>'ami-311f2b45',
    #            'flavor_id' =>'t1.micro',
    #            'key_name' => 'key-pair-name'
    #          }
    #
    def allocate_machine(action_handler, machine_spec, machine_options)
      # If the server does not exist, create it
      create_server(action_handler, machine_spec, machine_options)
    end

    def ready_machine(action_handler, machine_spec, machine_options)
      server = server_for(machine_spec)
      if server.nil?
        raise "Machine #{machine_spec.name} does not have a server associated with it, or server does not exist."
      end

      # Attach floating IPs if necessary
      attach_floating_ips(action_handler, machine_spec, machine_options, server)

      # Start the server if needed, and wait for it to start
      start_server(action_handler, machine_spec, server)
      wait_until_ready(action_handler, machine_spec, machine_options, server)
      begin
        wait_for_transport(action_handler, machine_spec, machine_options, server)
      rescue Fog::Errors::TimeoutError
        # Only ever reboot once, and only if it's been less than 10 minutes since we stopped waiting
        if machine.location['started_at'] || remaining_wait_time(machine_spec, machine_options) < -(10*60)
          raise
        else
          # Sometimes (on EC2) the machine comes up but gets stuck or has
          # some other problem.  If this is the case, we restart the server
          # to unstick it.  Reboot covers a multitude of sins.
          Chef::Log.warn "Machine #{machine_spec.name} (#{server.id} on #{driver_url}) was started but SSH did not come up.  Rebooting machine in an attempt to unstick it ..."
          restart_server(action_handler, machine_spec, machine_options, server)
          wait_until_ready(action_handler, machine_spec, machine_options, server)
          wait_for_transport(action_handler, machine_spec, machine_options, server)
        end
      end

      machine_for(machine_spec, server)
    end

    # Connect to machine without acquiring it
    def connect_to_machine(machine_spec)
      machine_for(machine_spec)
    end

    def delete_machine(action_handler, machine_spec)
      server = server_for(machine_spec)
      if server
        action_handler.perform_action "destroy machine #{machine_spec.name} (#{machine_spec.location['server_id']} at #{driver_url})" do
          server.destroy
          machine_spec.location = nil
        end
      end
      convergence_strategy_for(machine_spec).cleanup_convergence(action_handler, machine_spec)
    end

    def stop_machine(action_handler, machine_spec)
      server = server_for(machine_spec)
      if server
        action_handler.perform_action "stop machine #{machine_spec.name} (#{server.id} at #{driver_url})" do
          server.stop
        end
      end
    end

    def resource_created(machine)
      @base_bootstrap_options_for[ChefMetal::MachineSpec.id_from(machine.chef_server, machine.name)] = current_base_bootstrap_options
    end

    def compute
      @compute ||= Fog::Compute.new(compute_options)
    end

    def driver_url
      driver_identifier = case compute_options[:provider]
        when 'AWS'
          aws_login_info[0]
        when 'DigitalOcean'
          compute_options[:digitalocean_client_id]
        when 'OpenStack'
          compute_options[:openstack_auth_url]
        else
          '???'
      end
      "fog:#{compute_options[:provider]}:#{driver_identifier}"
    end

    # Not meant to be part of public interface
    def transport_for(server)
      # TODO winrm
      create_ssh_transport(server)
    end

    # TODO This is not particularly cool, but in the absence of better credentials
    # storage, it'll have to do. We're using global storage so that if you
    # create multiple provisioners of the same sort, they will share the same
    # key pairs. Ultimately, key pairs (and private keys in particular) should
    # be grabbed from the system and we should not rely on recipes creating them.
    def self.key_pairs
      @@key_pairs ||= {}
    end

    def self.add_key_pair(driver_url, name, fog_key_pair)
      key_pairs[driver_url] ||= {}
      key_pairs[driver_url][name] = fog_key_pair
    end

    protected

    def key_pairs
      ChefMetalFog::FogDriver.key_pairs[driver_url] ||= {}
    end

    def option_for(machine_options, key)
      if machine_options && machine_options[key.to_s]
        machine_options[key.to_s]
      elsif compute_options[key]
        compute_options[key]
      else
        DEFAULT_OPTIONS[key]
      end
    end

    def create_server(action_handler, machine_spec, machine_options)
      if machine_spec.location
        if machine_spec.location['driver_url'] != driver_url
          raise "Switching a machine's driver from #{machine_spec.location['driver_url']} to #{driver_url} for is not currently supported!  Use machine :destroy and then re-create the machine on the new driver."
        end

        server = server_for(machine_spec)
        if server
          if %w(terminated archive).include?(server.state) # Can't come back from that
            Chef::Log.warn "Machine #{machine_spec.name} (#{server.id} on #{driver_url}) is terminated.  Recreating ..."
          end
          return server
        else
          Chef::Log.warn "Machine #{machine_spec.name} (#{machine_spec.location['server_id']} on #{driver_url}) no longer exists.  Recreating ..."
        end
      end

      bootstrap_options = bootstrap_options_for(machine_spec, machine_options)

      description = [ "creating machine #{machine_spec.name} on #{driver_url}" ]
      bootstrap_options.each_pair { |key,value| description << "    #{key}: #{value.inspect}" }
      server = nil
      action_handler.report_progress description
      if action_handler.should_perform_actions
        creator = case compute_options[:provider]
          when 'AWS'
            aws_login_info[1]
          when 'OpenStack'
            compute_options[:openstack_username]
        end
        server = compute.servers.create(bootstrap_options)
        machine_spec.location = {
          'driver_url' => driver_url,
          'driver_version' => ChefMetalFog::VERSION,
          'server_id' => server.id,
          'creator' => creator,
          'allocated_at' => Time.now.utc.to_s,
          'is_windows' => option_for(machine_options, :is_windows),
          'chef_client_timeout' => option_for(machine_options, :chef_client_timeout)
        }
      end
      action_handler.performed_action "machine #{machine_spec.name} created as #{server.id} on #{driver_url}"
      server
    end

    def start_server(action_handler, machine_spec, server)
      # If it is stopping, wait for it to get out of "stopping" transition state before starting
      if server.state == 'stopping'
        action_handler.report_progress "wait for #{machine_spec.name} (#{server.id} on #{driver_url}) to finish stopping ..."
        server.wait_for { server.state != 'stopping' }
        action_handler.report_progress "#{machine_spec.name} is now stopped"
      end

      if server.state == 'stopped'
        action_handler.perform_action "start machine #{machine_spec.name} (#{server.id} on #{driver_url})" do
          server.start
          machine_spec.location['started_at'] = Time.now.utc.to_s
        end
      end
    end

    def restart_server(action_handler, machine_spec, server)
      action_handler.perform_action "restart machine #{machine_spec.name} (#{server.id} on #{driver_url})" do
        server.reboot
        machine_spec.location['started_at'] = Time.now.utc.to_s
      end
    end

    def remaining_wait_time(machine_spec, machine_options)
      if machine_spec.location['started_at']
        timeout = option_for(machine_options, :start_timeout) - (Time.now.utc - Time.parse(machine_spec.location['started_at']))
      else
        timeout = option_for(machine_options, :create_timeout) - (Time.now.utc - Time.parse(machine_spec.location['allocated_at']))
      end
    end

    def wait_until_ready(action_handler, machine_spec, machine_options, server)
      if !server.ready?
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{server.id} on #{driver_url}) to be ready ..."
          server.wait_for(remaining_wait_time(machine_spec, machine_options)) { ready? }
          action_handler.report_progress "#{machine_spec.name} is now ready"
        end
      end
    end

    def wait_for_transport(action_handler, machine_spec, machine_options, server)
      transport = transport_for(server)
      if !transport.available?
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{server.id} on #{driver_url}) to be connectable (transport up and running) ..."

          _self = self

          server.wait_for(remaining_wait_time(machine_spec, machine_options)) do
            transport.available?
          end
          action_handler.report_progress "#{machine_spec.name} is now connectable"
        end
      end
    end

    def attach_floating_ips(action_handler, machine_spec, machine_options, server)
      # TODO this is not particularly idempotent. OK, it is not idempotent AT ALL.  Fix.
      if option_for(machine_options, :floating_ip_pool)
        Chef::Log.info 'Attaching IP from pool'
        action_handler.perform_action "attach floating IP from #{option_for(machine_options, :floating_ip_pool)} pool" do
          attach_ip_from_pool(server, option_for(machine_options, :floating_ip_pool))
        end
      elsif option_for(machine_options, :floating_ip)
        Chef::Log.info 'Attaching given IP'
        action_handler.perform_action "attach floating IP #{option_for(machine_options, :floating_ip)}" do
          attach_ip(server, option_for(machine_options, :allocation_id), option_for(machine_options, :floating_ip))
        end
      end
    end

    # Attach IP to machine from IP pool
    # Code taken from kitchen-openstack driver
    #    https://github.com/test-kitchen/kitchen-openstack/blob/master/lib/kitchen/driver/openstack.rb#L196-L207
    def attach_ip_from_pool(server, pool)
      @ip_pool_lock ||= Mutex.new
      @ip_pool_lock.synchronize do
        Chef::Log.info "Attaching floating IP from <#{pool}> pool"
        free_addrs = compute.addresses.collect do |i|
          i.ip if i.fixed_ip.nil? and i.instance_id.nil? and i.pool == pool
        end.compact
        if free_addrs.empty?
          raise ActionFailed, "No available IPs in pool <#{pool}>"
        end
        attach_ip(server, free_addrs[0])
      end
    end

    # Attach given IP to machine
    # Code taken from kitchen-openstack driver
    #    https://github.com/test-kitchen/kitchen-openstack/blob/master/lib/kitchen/driver/openstack.rb#L209-L213
    def attach_ip(server, allocation_id, ip)
      Chef::Log.info "Attaching floating IP <#{ip}>"
      compute.associate_address(:instance_id => server.id,
                                :allocation_id => allocation_id,
                                :public_ip => ip)
    end

    # Returns [ Account ID, User ]
    # Account ID is the 12 digit identifier on your Manage Account page in AWS Console.  It is used as part of all ARNs identifying resources.
    # User is an identifier like "root" or "user/username" or "federated-user/username"
    def aws_login_info
      @aws_login_info ||= begin
        iam = Fog::AWS::IAM.new(:aws_access_key_id => compute_options[:aws_access_key_id], :aws_secret_access_key => compute_options[:aws_secret_access_key])
        arn = begin
          # TODO it would be nice if Fog let you do this normally ...
          iam.send(:request, {
            'Action'    => 'GetUser',
            :parser     => Fog::Parsers::AWS::IAM::GetUser.new
          }).body['User']['Arn']
        rescue Fog::AWS::IAM::Error
          # TODO Someone tell me there is a better way to find out your current
          # user ID than this!  This is what happens when you use an IAM user
          # with default privileges.
          if $!.message =~ /AccessDenied.+(arn:aws:iam::\d+:\S+)/
            arn = $1
          else
            raise
          end
        end
        arn.split(':')[4..5]
      end
    end

    def symbolize_keys(options)
      options.inject({}) { |result,(key,value)| result[key.to_sym] = value; result }
    end

    def server_for(machine_spec)
      if machine_spec.location
        compute.servers.get(machine_spec.location['server_id'])
      else
        nil
      end
    end

    def bootstrap_options_for(machine_spec, machine_options)
      bootstrap_options = @base_bootstrap_options_for[machine_spec.id] || current_base_bootstrap_options
      bootstrap_options.merge!(symbolize_keys(machine_options || {}))
      tags = {
          'Name' => machine_spec.name,
          'BootstrapChefServer' => machine_spec.chef_server[:chef_server_url],
          'BootstrapHost' => Socket.gethostname,
          'BootstrapUser' => Etc.getlogin,
          'BootstrapNodeName' => machine_spec.name
      }
      # TODO add a status endpoint to chef-zero that reports this
      if machine_spec.chef_server[:options] && machine_spec.chef_server[:options][:data_store]
        tags['ChefLocalRepository'] = machine_spec.chef_server[:options][:data_store].chef_fs.fs_description
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
        bootstrap_options[:name] = machine_spec.name
      end

      bootstrap_options.merge!(:name => machine_spec.name)

      bootstrap_options
    end

    def machine_for(machine_spec, server = nil)
      server ||= server_for(machine_spec)
      if !server
        raise "Server for node #{machine_spec.name} has not been created!"
      end

      if option_for(machine_spec.location, :is_windows)
        ChefMetal::Machine::WindowsMachine.new(machine_spec, transport_for(server), convergence_strategy_for(machine_spec))
      else
        ChefMetal::Machine::UnixMachine.new(machine_spec, transport_for(server), convergence_strategy_for(machine_spec))
      end
    end

    def convergence_strategy_for(machine_spec)
      options = {}
      if option_for(machine_spec.location, :chef_client_timeout)
        options[:chef_client_timeout] = option_for(machine_spec.location, :chef_client_timeout)
      end

      if option_for(machine_spec.location, :is_windows)
        ChefMetal::ConvergenceStrategy::InstallMsi.new(options)
      else
        ChefMetal::ConvergenceStrategy::InstallCached.new(options)
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
        result[:key_data] = [ server.private_key ]
      elsif server.respond_to?(:key_name) && key_pairs[server.key_name]
        # TODO generalize for others?
        result[:keys] ||= [ key_pairs[server.key_name].private_key_path ]
      else
        if key_pairs.size == 0
          raise "No key pairs found!  Did you forget to declare a fog_key_pair?"
        end
        # TODO need a way to know which key if there were multiple
        result[:keys] = [ key_pairs.first[1].private_key_path ]
      end
      result
    end

    def create_ssh_transport(server)
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
      elsif !server.public_ip_address
        Chef::Log.warn("Server has no public ip address.  Using private ip '#{server.private_ip_address}'.  Set driver option 'use_private_ip_for_ssh' => true if this will always be the case ...")
        remote_host = server.private_ip_address
      elsif server.public_ip_address
        remote_host = server.public_ip_address
      else
        raise "Server #{server.id} has no private or public IP address!"
      end

      #Enable pty by default
      options[:ssh_pty_enable] = true
      options[:ssh_gateway] = compute_options[:ssh_gateway] if compute_options.key?(:ssh_gateway)

      ChefMetal::Transport::SSH.new(remote_host, username, ssh_options, options)
    end
  end
end
