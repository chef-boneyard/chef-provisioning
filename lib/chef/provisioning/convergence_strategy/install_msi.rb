require 'chef/provisioning/convergence_strategy/precreate_chef_objects'
require 'mixlib/install/script_generator'
require 'pathname'

class Chef
module Provisioning
  class ConvergenceStrategy
    class InstallMsi < PrecreateChefObjects
      def initialize(convergence_options, config)
        super
        @chef_version ||= convergence_options[:chef_version]
        @prerelease ||= convergence_options[:prerelease]
        @chef_client_timeout = convergence_options.has_key?(:chef_client_timeout) ? convergence_options[:chef_client_timeout] : 120*60 # Default: 2 hours
      end

      attr_reader :chef_version
      attr_reader :prerelease
      attr_reader :install_msi_url
      attr_reader :install_msi_path

      def setup_convergence(action_handler, machine)
        if !convergence_options.has_key?(:client_rb_path) || !convergence_options.has_key?(:client_pem_path)
          system_drive = machine.system_drive
          @convergence_options = Cheffish::MergedConfig.new(convergence_options, {
            :client_rb_path => "#{system_drive}\\chef\\client.rb",
            :client_pem_path => "#{system_drive}\\chef\\client.pem",
            :install_script_path => "#{system_drive}\\chef\\\install.ps1"
          })
        end

        opts = {"prerelease" => prerelease}
        if convergence_options[:bootstrap_proxy]
          opts["http_proxy"] = convergence_options[:bootstrap_proxy]
          opts["https_proxy"] = convergence_options[:bootstrap_proxy]
        end
        opts["install_msi_url"] = convergence_options[:install_msi_url] if convergence_options[:install_msi_url]
        super

        install_command = Mixlib::Install::ScriptGenerator.new(chef_version, true, opts).install_command
        machine.write_file(action_handler, convergence_options[:install_script_path], install_command)

        action_handler.open_stream(machine.node['name']) do |stdout|
          action_handler.open_stream(machine.node['name']) do |stderr|
            machine.execute(action_handler, "& \"#{convergence_options[:install_script_path]}\"",
              :stream_stdout => stdout,
              :stream_stderr => stderr)
          end
        end
      end

      def converge(action_handler, machine)
        super

        action_handler.open_stream(machine.node['name']) do |stdout|
          action_handler.open_stream(machine.node['name']) do |stderr|
            # We just installed chef in this shell so refresh PATH from System.Environment
            command_line = "$env:path = [System.Environment]::GetEnvironmentVariable('PATH', 'MACHINE');"
            command_line << "chef-client"
            command_line << " -l #{config[:log_level].to_s}" if config[:log_level]
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
