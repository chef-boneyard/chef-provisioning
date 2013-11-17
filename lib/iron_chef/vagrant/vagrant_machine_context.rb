require 'chef/mixin/shell_out'
require 'iron_chef/machine_context_base'
require 'iron_chef/vagrant/vagrant_machine_context_resources'
# TODO consider doing the require inline so we don't load these things unless they are needed
require 'iron_chef/transport/ssh'
require 'iron_chef/transport/vagrant_ssh'

module IronChef
  module Vagrant
    class VagrantMachineContext < MachineContextBase
      include Chef::Mixin::ShellOut

      def initialize(bootstrapper, name)
        super
      end

      def configuration_path
        "/etc/chef"
      end

      def resources(recipe_context)
        result = VagrantMachineContextResources.new(self, recipe_context)
        result.instance_eval(lambda { yield self }) if block_given?
        result
      end

      def transport
        @transport ||= begin
          options = bootstrapper.transport_options
          case options[:type]
          when :vagrant_ssh
            IronChef::Transport::VagrantSSH.new(bootstrapper.base_path, name)
          else
            vagrant_ssh_config = get_ssh_config
            username = options[:username] || vagrant_ssh_config['User']
            ssh_options = options[:options] ? options[:options].dup : {}
            ssh_options[:port] ||= vagrant_ssh_config['Port']
            ssh_options[:user_known_hosts_file] ||= vagrant_ssh_config['UserKnownHostsFile']
            ssh_options[:paranoid] ||= yes_or_no(vagrant_ssh_config['StrictHostKeyChecking'])
            ssh_options[:keys] ||= []
            ssh_options[:keys] << strip_quotes(vagrant_ssh_config['IdentityFile'])
            ssh_options[:keys_only] ||= yes_or_no(vagrant_ssh_config['IdentitiesOnly'])
            ssh_options[:auth_methods] = %w(password) if yes_or_no(vagrant_ssh_config['PasswordAuthentication'])
            IronChef::Transport::SSH.new(vagrant_ssh_config['HostName'], username, ssh_options)
          end
        end
      end


      def get_ssh_config
        vagrant("ssh-config --host #{name}").stdout.lines.inject({}) do |result, line|
          line =~ /^\s*(\S+)\s+(.+)/
          result[$1] = $2
          result
        end
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

      # Used by VagrantMachineContext to get the string used to configure vagrant
      def vagrant_config_string(variable, line_prefix)
        hostname = name.gsub(/[^A-Za-z0-9\-]/, '-')

        result = ''
        bootstrapper.vagrant_config.merge(:hostname => hostname).each_pair do |key, value|
          result += "#{line_prefix}#{variable}.#{key} = #{value.inspect}\n"
        end
        result
      end

      def box_file_path
        File.join(bootstrapper.base_path, "#{name}.vm")
      end

      def box_file_exists
        File.exist?(box_file_path)
      end

      def vagrant(command)
        shell_out("vagrant #{command}", :cwd => bootstrapper.base_path)
      end
    end
  end
end