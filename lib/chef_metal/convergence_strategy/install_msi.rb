require 'chef_metal/convergence_strategy/precreate_chef_objects'
require 'pathname'

module ChefMetal
  class ConvergenceStrategy
    class InstallMsi < PrecreateChefObjects
      @@install_msi_cache = {}

      def initialize(options = {})
        @install_msi_url = options[:install_msi_url] || 'http://www.opscode.com/chef/install.msi'
        @install_msi_path = options[:install_msi_path] || "%TEMP%\\#{File.basename(@install_msi_url)}"
        @chef_client_timeout = options.has_key?(:chef_client_timeout) ? options[:chef_client_timeout] : 120*60 # Default: 2 hours
      end

      attr_reader :install_msi_url
      attr_reader :install_msi_path

      def setup_convergence(action_handler, machine, machine_resource)
        system_drive = machine.execute_always('$env:SystemDrive').stdout.strip
        @client_rb_path ||= "#{system_drive}\\chef\\client.rb"
        @client_pem_path ||= "#{system_drive}\\chef\\client.pem"

        super

        # Install chef-client.  TODO check and update version if not latest / not desired
        if machine.execute_always('chef-client -v').exitstatus != 0
          # TODO ssh verification of install.sh before running arbtrary code would be nice?
          # TODO find a way to cache this on the host like with the Unix stuff.
          # Limiter is we don't know how to efficiently upload large files to
          # the remote machine with WMI.
          machine.execute(action_handler, "(New-Object System.Net.WebClient).DownloadFile(#{machine.escape(install_msi_url)}, #{machine.escape(install_msi_path)})")
          machine.execute(action_handler, "msiexec /qn /i #{machine.escape(install_msi_path)}")
        end
      end

      def converge(action_handler, machine)
        # TODO For some reason I get a 500 back if I don't do -l debug
        machine.execute(action_handler, "chef-client -l debug", :stream => true, :timeout => @chef_client_timeout)
      end
    end
  end
end
