require 'chef/mixin/shell_out'
require 'iron_chef/provisioner'

module IronChef
  module Vagrant

    # Provisions machines in vagrant.
    class VagrantProvisioner < Provisioner

      include Chef::Mixin::ShellOut

      # Create a new vagrant provisioner.
      #
      # ## Parameters
      # cluster_path - path to the directory containing the vagrant files, which
      #                should have been created with the vagrant_cluster resource.
      # vagrant_options - options to use for vagrant boxes provisioned by this
      #                   resource.  In the form of properties of the "config"
      #                   object, e.g. "vm.box" => "ubuntu12" and "vm.box_url"
      #                   => "http://...."
      def initialize(cluster_path, vagrant_options)
        @cluster_path = cluster_path
        @vagrant_options = vagrant_options
      end

      attr_reader :cluster_path
      attr_reader :vagrant_options

      # Acquire a machine, generally by provisioning it.  Returns a Machine
      # object pointing at the machine, allowing useful actions like setup,
      # converge, execute, file and directory.  The Machine object will have a
      # "node" property which must be saved to the server (if it is any
      # different from the original node object).
      #
      # This method does 
      # ## Parameters
      # provider_context - the provider object that is calling this method.
      # node - node object (deserialized json) representing this machine.  If
      #        the node has a vagrant_options hash in it, these will be used
      #        instead of options provided by the provisioner.  TODO compare and
      #        fail if different?
      # provisioner_options - specific options for this machine provisioner.  These
      #        options will be merged with the existing provider options. For
      #        vagrant, it is a hash of vagrant options (such as 'vm.box' =>
      #        'ubuntu12')
      def acquire_machine(provider, node, provisioner_options)
        merged_vagrant_options = { 'vm.hostname' => node['name'] }.merge(vagrant_options)
        merged_vagrant_options = merged_vagrant_options.merge(provisioner_options) if provisioner_options

        # TODO compare new options to existing and fail if we cannot change it
        # over (perhaps introduce a boolean that will force a delete and recreate
        # in such a case)
        node['vagrant_provisioner'] = {
          'vm_file_path' => File.join(cluster_path, "#{node['name']}.vm"),
          'vagrant_options' => merged_vagrant_options
        }

        # Set up vagrant
        IronChef.inline_resource(provider) do
          file node['vagrant_provisioner']['vm_file_path'] do
            content <<EOM
Vagrant.configure("2") do |config|
config.vm.define #{node['name'].inspect} do |machine|
#{VagrantProvisioner::vagrant_config_string(merged_vagrant_options, 'machine', '    ')}
end
end
EOM
            action :create
          end
        end

        # Check current status of vm
        current_status = vagrant_status(node['name'])

        # Run vagrant up if vm is not running
        if current_status != 'running'
          provider.converge_by "run vagrant up #{node['name']} (status was '#{current_status}')" do
            result = shell_out("vagrant up #{node['name']}", :cwd => cluster_path)
            if result.exitstatus != 0
              raise "vagrant up failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
          end
        end

        # Create machine object for callers to use
        machine_for(node)
      end

      def delete_machine(provider, node)
        current_status = vagrant_status(node['name'])
        if current_status != 'not created'
          provider.converge_by "run vagrant destroy -f #{node['name']} (status was '#{current_status}')" do
            result = shell_out("vagrant destroy -f #{node['name']}", :cwd => cluster_path)
            if result.exitstatus != 0
              raise "vagrant destroy failed!\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
            end
          end
        end

        convergence_strategy_for(node).delete_chef_objects(provider, node)

        vm_file_path = File.join(cluster_path, "#{node['name']}.vm")
        IronChef.inline_resource(provider) do
          file vm_file_path do
            action :delete
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

      def machine_for(node)
        if vagrant_option(node, 'vm.guest') == :windows
          require 'iron_chef/machine/windows_machine'
          IronChef::Machine::WindowsMachine.new(node, transport_for(node), convergence_strategy_for(node))
        else
          require 'iron_chef/machine/unix_machine'
          IronChef::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
        end
      end

      def convergence_strategy_for(node)
        if vagrant_option(node, 'vm.guest') == :windows
          require 'iron_chef/convergence_strategy/install_msi'
          IronChef::ConvergenceStrategy::InstallMsi.new
        else
          require 'iron_chef/convergence_strategy/install_sh'
          IronChef::ConvergenceStrategy::InstallSh.new
        end
      end

      def transport_for(node)
        if vagrant_option(node, 'vm.guest') == :windows
          create_winrm_transport(node)
        else
          create_ssh_transport(node)
        end
      end

      def vagrant_option(node, option)
        if node['vagrant_provisioner'] &&
           node['vagrant_provisioner']['vagrant_options']
          node['vagrant_provisioner']['vagrant_options'][option]
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

      def create_ssh_transport(node)
        require 'iron_chef/transport/ssh'

        vagrant_ssh_config = {}
        shell_out("vagrant ssh-config --host #{node['name']}", :cwd => cluster_path).stdout.lines.inject({}) do |result, line|
          line =~ /^\s*(\S+)\s+(.+)/
          vagrant_ssh_config[$1] = $2
        end
        hostname = vagrant_ssh_config['HostName']
        username = vagrant_ssh_config['User']
        ssh_options = {
          :port => vagrant_ssh_config['Port'],
          :user_known_hosts_file => vagrant_ssh_config['UserKnownHostsFile'],
          :paranoid => yes_or_no(vagrant_ssh_config['StrictHostKeyChecking']),
          :keys => [ strip_quotes(vagrant_ssh_config['IdentityFile']) ],
          :keys_only => yes_or_no(vagrant_ssh_config['IdentitiesOnly'])
        }
        ssh_options[:auth_methods] = %w(password) if yes_or_no(vagrant_ssh_config['PasswordAuthentication'])
        IronChef::Transport::SSH.new(hostname, username, ssh_options)
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