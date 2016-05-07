require 'chef/provisioning/convergence_strategy/precreate_chef_objects'
require 'pathname'
require 'mixlib/install/script_generator'

class Chef
module Provisioning
  class ConvergenceStrategy
    class InstallSh < PrecreateChefObjects
      @@install_sh_cache = {}

      def initialize(convergence_options, config)
        convergence_options = Cheffish::MergedConfig.new(convergence_options, {
          :client_rb_path => '/etc/chef/client.rb',
          :client_pem_path => '/etc/chef/client.pem'
        })
        super(convergence_options, config)
        @client_rb_path ||= convergence_options[:client_rb_path]
        @install_sh_path = convergence_options[:install_sh_path] || '/tmp/chef-install.sh'
        @chef_version = convergence_options[:chef_version]
        @prerelease = convergence_options[:prerelease]
        @install_sh_arguments = convergence_options[:install_sh_arguments]
        @bootstrap_env = convergence_options[:bootstrap_proxy] ? "http_proxy=#{convergence_options[:bootstrap_proxy]} https_proxy=$http_proxy " : ""
        @chef_client_timeout = convergence_options.has_key?(:chef_client_timeout) ? convergence_options[:chef_client_timeout] : 120*60 # Default: 2 hours
      end

      attr_reader :client_rb_path
      attr_reader :chef_version
      attr_reader :prerelease
      attr_reader :install_sh_path
      attr_reader :install_sh_arguments
      attr_reader :bootstrap_env

      def setup_convergence(action_handler, machine)
        super

        opts = {"prerelease" => prerelease}
        if convergence_options[:bootstrap_proxy]
          opts["http_proxy"] = convergence_options[:bootstrap_proxy]
          opts["https_proxy"] = convergence_options[:bootstrap_proxy]
        end

        if convergence_options[:install_sh_arguments]
          opts['install_flags'] = convergence_options[:install_sh_arguments]
        end

        install_command = Mixlib::Install::ScriptGenerator.new(chef_version, false, opts).install_command
        machine.write_file(action_handler, install_sh_path, install_command, :ensure_dir => true)
        machine.set_attributes(action_handler, install_sh_path, :mode => '0755')
        machine.execute(action_handler, "sh -c #{install_sh_path}")
      end

      def converge(action_handler, machine)
        super

        action_handler.open_stream(machine.node['name']) do |stdout|
          action_handler.open_stream(machine.node['name']) do |stderr|
            command_line = "chef-client"
            command_line << " -c #{@client_rb_path} -l #{config[:log_level].to_s}" if config[:log_level]
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
end
