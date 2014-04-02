require 'chef/mixin/shell_out'
require 'chef_metal/provisioner'

module ChefMetal
  class Provisioner

    # Provisions machines in vagrant.
    class VagrantProvisioner < Provisioner

      include Chef::Mixin::ShellOut
      # Create a new vagrant provisioner.
      #
      # ## Parameters
      # cluster_path - path to the directory containing the vagrant files, which
      #                should have been created with the vagrant_cluster resource.
      def initialize(cluster_path)
        @cluster_path = cluster_path
      end

      attr_reader :cluster_path

      # Inflate a provisioner from node information; we don't want to force the
      # driver to figure out what the provisioner really needs, since it varies
      # from provisioner to provisioner.
      #
      # ## Parameters
      # node - node to inflate the provisioner for
      #
      # returns a VagrantProvisioner
      def self.inflate(node)
        node_url = node['normal']['provisioner_output']['provisioner_url']
        cluster_path = node_url.split(':', 2)[1].sub(/^\/\//, "")
        self.new(cluster_path)
      end

      # Acquire a machine, generally by provisioning it.  Returns a Machine
      # object pointing at the machine, allowing useful actions like setup,
      # converge, execute, file and directory.  The Machine object will have a
      # "node" property which must be saved to the server (if it is any
      # different from the original node object).
      #
      # ## Parameters
      # action_handler - the action_handler object that is calling this method; this
      #        is generally a provider, but could be anything that can support the
      #        ChefMetal::ActionHandler interface (i.e., in the case of the test
      #        kitchen metal driver for acquiring and destroying VMs; see the base
      #        class for what needs providing).
      # node - node object (deserialized json) representing this machine.  If
      #        the node has a provisioner_options hash in it, these will be used
      #        instead of options provided by the provisioner.  TODO compare and
      #        fail if different?
      #        node will have node['normal']['provisioner_options'] in it with any options.
      #        It is a hash with this format:
      #
      #           -- provisioner_url: vagrant:<cluster_path>
      #           -- vagrant_options: hash of properties of the "config"
      #              object, i.e. "vm.box" => "ubuntu12" and "vm.box_url"
      #           -- vagrant_config: string containing other vagrant config.
      #              Should assume the variable "config" represents machine config.
      #              Will be written verbatim into the vm's Vagrantfile.
      #           -- transport_options: hash of options specifying the transport.
      #                :type => :ssh
      #                :type => :winrm
      #                If not specified, ssh is used unless vm.guest is :windows.  If that is
      #                the case, the windows options are used and the port forward for 5985
      #                is detected.
      #           -- up_timeout: maximum time, in seconds, to wait for vagrant
      #              to bring up the machine.  Defaults to 10 minutes.
      #
      #        node['normal']['provisioner_output'] will be populated with information
      #        about the created machine.  For vagrant, it is a hash with this
      #        format:
      #
      #           -- provisioner_url: vagrant_cluster://<current_node>/<cluster_path>
      #           -- vm_name: name of vagrant vm created
      #           -- vm_file_path: path to machine-specific vagrant config file
      #              on disk
      #           -- forwarded_ports: hash with key as guest_port => host_port
      #
      def acquire_machine(action_handler, node)
        # Set up the modified node data
        provisioner_options = node['normal']['provisioner_options']
        vm_name = node['name']
        old_provisioner_output = node['normal']['provisioner_output']
        node['normal']['provisioner_output'] = provisioner_output = {
          'provisioner_url' => provisioner_url(action_handler),
          'vm_name' => vm_name,
          'vm_file_path' => File.join(cluster_path, "#{vm_name}.vm")
        }
        # Preserve existing forwarded ports
        provisioner_output['forwarded_ports'] = old_provisioner_output['forwarded_ports'] if old_provisioner_output

        # TODO compare new options to existing and fail if we cannot change it
        # over (perhaps introduce a boolean that will force a delete and recreate
        # in such a case)

        # Determine contents of vm file
        vm_file_content = "Vagrant.configure('2') do |outer_config|\n"
        vm_file_content << "  outer_config.vm.define #{vm_name.inspect} do |config|\n"
        merged_vagrant_options = { 'vm.hostname' => node['name'] }
        merged_vagrant_options.merge!(provisioner_options['vagrant_options']) if provisioner_options['vagrant_options']
        merged_vagrant_options.each_pair do |key, value|
          vm_file_content << "    config.#{key} = #{value.inspect}\n"
        end
        vm_file_content << provisioner_options['vagrant_config'] if provisioner_options['vagrant_config']
        vm_file_content << "  end\nend\n"

        # Set up vagrant file
        vm_file = ChefMetal.inline_resource(action_handler) do
          file provisioner_output['vm_file_path'] do
            content vm_file_content
            action :create
          end
        end

        # Check current status of vm
        current_status = vagrant_status(vm_name)
        up_timeout = provisioner_options['up_timeout'] || 10*60

        if current_status != 'running'
          # Run vagrant up if vm is not running
          action_handler.perform_action "run vagrant up #{vm_name} (status was '#{current_status}')" do
            result = shell_out("vagrant up #{vm_name}", :cwd => cluster_path, :timeout => up_timeout)
            if result.exitstatus != 0
              raise "vagrant up #{vm_name} failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
            parse_vagrant_up(result.stdout, node)
          end
        elsif vm_file.updated_by_last_action?
          # Run vagrant reload if vm is running and vm file changed
          action_handler.perform_action "run vagrant reload #{vm_name}" do
            result = shell_out("vagrant reload #{vm_name}", :cwd => cluster_path, :timeout => up_timeout)
            if result.exitstatus != 0
              raise "vagrant reload #{vm_name} failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
            parse_vagrant_up(result.stdout, node)
          end
        end

        # Create machine object for callers to use
        machine_for(node)
      end

      # Connect to machine without acquiring it
      def connect_to_machine(node)
        machine_for(node)
      end

      def delete_machine(action_handler, node)
        if node['normal'] && node['normal']['provisioner_output']
          provisioner_output = node['normal']['provisioner_output']
        else
          provisioner_output = {}
        end
        vm_name = provisioner_output['vm_name'] || node['name']
        current_status = vagrant_status(vm_name)
        if current_status != 'not created'
          action_handler.perform_action "run vagrant destroy -f #{vm_name} (status was '#{current_status}')" do
            result = shell_out("vagrant destroy -f #{vm_name}", :cwd => cluster_path)
            if result.exitstatus != 0
              raise "vagrant destroy failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
          end
        end

        convergence_strategy_for(node).delete_chef_objects(action_handler, node)

        vm_file_path = provisioner_output['vm_file_path'] || File.join(cluster_path, "#{vm_name}.vm")
        ChefMetal.inline_resource(action_handler) do
          file vm_file_path do
            action :delete
          end
        end
      end

      def stop_machine(action_handler, node)
        if node['normal'] && node['normal']['provisioner_output']
          provisioner_output = node['normal']['provisioner_output']
        else
          provisioner_output = {}
        end
        vm_name = provisioner_output['vm_name'] || node['name']
        current_status = vagrant_status(vm_name)
        if current_status == 'running'
          action_handler.perform_action "run vagrant halt #{vm_name} (status was '#{current_status}')" do
            result = shell_out("vagrant halt #{vm_name}", :cwd => cluster_path)
            if result.exitstatus != 0
              raise "vagrant halt failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
          end
        end
      end


      # Used by vagrant_cluster and machine to get the string used to configure vagrant
      def self.vagrant_config_string(vagrant_config, variable, line_prefix)
        hostname = name.gsub(/[^A-Za-z0-9\-]/, '-')

        result = ''
        vagrant_config.each_pair do |key, value|
          result += "#{line_prefix}#{variable}.#{key} = #{value.inspect}\n"
        end
        result
      end

      protected

      def provisioner_url(action_handler)
        "vagrant_cluster://#{action_handler.node['name']}#{cluster_path}"
      end

      def parse_vagrant_up(output, node)
        # Grab forwarded port info
        in_forwarding_ports = false
        output.lines.each do |line|
          if in_forwarding_ports
            if line =~ /-- (\d+) => (\d+)/
              node['normal']['provisioner_output']['forwarded_ports'][$1] = $2
            else
              in_forwarding_ports = false
            end
          elsif line =~ /Forwarding ports...$/
            node['normal']['provisioner_output']['forwarded_ports'] = {}
            in_forwarding_ports = true
          end
        end
      end

      def machine_for(node)
        if vagrant_option(node, 'vm.guest').to_s == 'windows'
          require 'chef_metal/machine/windows_machine'
          ChefMetal::Machine::WindowsMachine.new(node, transport_for(node), convergence_strategy_for(node))
        else
          require 'chef_metal/machine/unix_machine'
          ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
        end
      end

      def convergence_strategy_for(node)
        if vagrant_option(node, 'vm.guest').to_s == 'windows'
          require 'chef_metal/convergence_strategy/install_msi'
          ChefMetal::ConvergenceStrategy::InstallMsi.new
        else
          require 'chef_metal/convergence_strategy/install_sh'
          ChefMetal::ConvergenceStrategy::InstallSh.new
        end
      end

      def transport_for(node)
        if vagrant_option(node, 'vm.guest').to_s == 'windows'
          create_winrm_transport(node)
        else
          create_ssh_transport(node)
        end
      end

      def vagrant_option(node, option)
        if node['normal']['provisioner_options'] &&
           node['normal']['provisioner_options']['vagrant_options']
          node['normal']['provisioner_options']['vagrant_options'][option]
        else
          nil
        end
      end

      def vagrant_status(name)
        status_output = shell_out("vagrant status #{name}", :cwd => cluster_path).stdout
        if status_output =~ /^#{name}\s+([^\n]+)\s+\(([^\n]+)\)$/m
          $1
        else
          'not created'
        end
      end

      def create_winrm_transport(node)
        require 'chef_metal/transport/winrm'

        provisioner_output = node['default']['provisioner_output'] || {}
        forwarded_ports = provisioner_output['forwarded_ports'] || {}

        # TODO IPv6 loopback?  What do we do for that?
        hostname = vagrant_option(node, 'winrm.host') || '127.0.0.1'
        port = vagrant_option(node, 'winrm.port') || forwarded_ports[5985] || 5985
        endpoint = "http://#{hostname}:#{port}/wsman"
        type = :plaintext
        options = {
          :user => vagrant_option(node, 'winrm.username') || 'vagrant',
          :pass => vagrant_option(node, 'winrm.password') || 'vagrant',
          :disable_sspi => true
        }

        ChefMetal::Transport::WinRM.new(endpoint, type, options)
      end

      def create_ssh_transport(node)
        require 'chef_metal/transport/ssh'

        vagrant_ssh_config = vagrant_ssh_config_for(node)
        hostname = vagrant_ssh_config['HostName']
        username = vagrant_ssh_config['User']
        ssh_options = {
          :port => vagrant_ssh_config['Port'],
          :auth_methods => ['publickey'],
          :user_known_hosts_file => vagrant_ssh_config['UserKnownHostsFile'],
          :paranoid => yes_or_no(vagrant_ssh_config['StrictHostKeyChecking']),
          :keys => [ strip_quotes(vagrant_ssh_config['IdentityFile']) ],
          :keys_only => yes_or_no(vagrant_ssh_config['IdentitiesOnly'])
        }
        ssh_options[:auth_methods] = %w(password) if yes_or_no(vagrant_ssh_config['PasswordAuthentication'])
        options = {
          :prefix => 'sudo '
        }
        ChefMetal::Transport::SSH.new(hostname, username, ssh_options, options)
      end

      def vagrant_ssh_config_for(node)
        vagrant_ssh_config = {}
        result = shell_out("vagrant ssh-config #{node['normal']['provisioner_output']['vm_name']}", :cwd => cluster_path)
        result.stdout.lines.inject({}) do |result, line|
          line =~ /^\s*(\S+)\s+(.+)/
          vagrant_ssh_config[$1] = $2
        end
        vagrant_ssh_config
      end

      def yes_or_no(str)
        case str
        when 'yes'
          true
        else
          false
        end
      end

      def strip_quotes(str)
        if str[0] == '"' && str[-1] == '"' && str.size >= 2
          str[1..-2]
        else
          str
        end
      end
    end
  end
end
