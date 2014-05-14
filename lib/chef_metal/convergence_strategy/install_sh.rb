require 'chef_metal/convergence_strategy/precreate_chef_objects'
require 'pathname'

module ChefMetal
  class ConvergenceStrategy
    class InstallSh < PrecreateChefObjects
      @@install_sh_cache = {}

      def initialize(options = {})
        super
        @install_sh_url = options[:install_sh_url] || 'http://www.opscode.com/chef/install.sh'
        @install_sh_path = options[:install_sh_path] || '/tmp/chef-install.sh'
        @client_rb_path ||= '/etc/chef/client.rb'
        @client_pem_path ||= '/etc/chef/client.pem'
        @chef_client_timeout = options.has_key?(:chef_client_timeout) ? options[:chef_client_timeout] : 120*60 # Default: 2 hours
      end

      attr_reader :install_sh_url
      attr_reader :install_sh_path

      def setup_convergence(action_handler, machine, options)
        super

        # Install chef-client.  TODO check and update version if not latest / not desired
        if machine.execute_always('chef-client -v').exitstatus != 0
          # TODO ssh verification of install.sh before running arbtrary code would be nice?
          @@install_sh_cache[install_sh_url] ||= Net::HTTP.get(URI(install_sh_url))
          machine.write_file(action_handler, install_sh_path, @@install_sh_cache[install_sh_url], :ensure_dir => true)
          machine.execute(action_handler, "bash #{install_sh_path}")
        end
      end

      def converge(action_handler, machine)
        super

        action_handler.open_stream(machine.node['name']) do |stdout|
          action_handler.open_stream(machine.node['name']) do |stderr|
            command_line = "chef-client"
            command_line << "-l #{log_level.to_s}" if log_level
            machine.execute(action_handler, command_line,
              :stream_stdout => stdout,
              :stream_stderr => stderr,
              :timeout => @chef_client_timeout)
          end
        end
      end
    end
  end
end
