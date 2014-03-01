require 'chef/mixin/shell_out'
require 'chef_metal/provisioner'

module ChefMetal
  class Provisioner

    # Provisions machines in lxc.
    class LXCProvisioner < Provisioner

      include Chef::Mixin::ShellOut

      # Create a new LXC provisioner.
      #
      def initialize(lxc_path=nil)
        @lxc_path = lxc_path
      end

      attr_reader :lxc_path

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
      #           -- provisioner_url: lxc://<lxc_path>
      #           -- template: template name
      #           -- template_options: ???
      #           -- backingstore: ???
      #
      #        node['normal']['provisioner_output'] will be populated with information
      #        about the created machine.  For vagrant, it is a hash with this
      #        format:
      #
      #           -- provisioner_url: lxc://<lxc_path>
      #           -- lxc_path: path to lxc root
      #           -- name: container name
      #
      def acquire_machine(provider, node)
        # TODO verify that the existing provisioner_url in the node is the same as ours

        # Set up the modified node data
        provisioner_options = node['normal']['provisioner_options']
        provisioner_output = node['normal']['provisioner_output'] || {
          'provisioner_url' => provisioner_url(),
          'name' => node['name']
        }

        # Create the container if it does not exist
        ct = LXC::Container.new(provisioner_output['name'], lxc_path)
        if !ct.exists?
          provider.converge_by "create lxc container #{provisioner_output['name']}" do
            ct.create(provisioner_options['template'], provisioner_options['backingstore'], 0, provisioner_options['template_options'])
            ct.start
          end
        end

        if true # do a check on whether sshd is installed.  This is idempotency!
          provider.converge_by "install ssh into container #{provisioner_output['name']}" do
            ct.attach('apt-get install sshd') # ?????
          end
        end

        node['normal']['provisioner_output'] = provisioner_output

        # Create machine object for callers to use
        machine_for(node)
      end

      # Connect to machine without acquiring it
      def connect_to_machine(node)
        machine_for(node)
      end

      def delete_machine(provider, node)
        if node['normal'] && node['normal']['provisioner_output']
          provisioner_output = node['normal']['provisioner_output']
          ct = LXC::Container.new(provisioner_output['name'], lxc_path)
          if ct.exists?
            provider.converge_by "delete lxc container #{provisioner_output['name']}" do
              ct.destroy
            end
          end
        end

        convergence_strategy_for(node).delete_chef_objects(provider, node)
      end

      def stop_machine(provider, node)
        if node['normal'] && node['normal']['provisioner_output']
          provisioner_output = node['normal']['provisioner_output']
          ct = LXC::Container.new(provisioner_output['name'], lxc_path)
          if ct.running?
            provider.converge_by "delete lxc container #{provisioner_output['name']}" do
              ct.stop
            end
          end
        end
      end

      protected

      def provisioner_url
        "lxc://#{lxc_path}"
      end

      def machine_for(node)
        require 'chef_metal/machine/unix_machine'
        ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
      end

      def convergence_strategy_for(node)
        require 'chef_metal/convergence_strategy/install_sh'
        ChefMetal::ConvergenceStrategy::InstallSh.new
      end

      def transport_for(node)
        require 'chef_metal/transport/ssh'

        # TODO This is the stuff vagrant uses ... we need to pick our own values
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
    end
  end
end
