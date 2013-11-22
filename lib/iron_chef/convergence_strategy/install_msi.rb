require 'iron_chef/convergence_strategy/precreate_chef_objects'

module IronChef
  class ConvergenceStrategy
    class InstallMsi < PrecreateChefObjects
      @@install_msi_cache = {}

      def initialize(options = {})
        @install_msi_url = options[:install_msi_url] || 'http://www.opscode.com/chef/install.msi'
        @install_msi_path = options[:install_msi_path] || "%TEMP%\\#{File.basename(@install_msi_url)}"
        @client_rb_path ||= '/etc/chef/client.rb'
        @client_pem_path ||= '/etc/chef/client.pem'
      end

      attr_reader :install_sh_url
      attr_reader :install_sh_path

      def setup_convergence(provider, machine, machine_resource)
        super

        # Install chef-client.  TODO check and update version if not latest / not desired
        if machine.execute_always('chef-client -v').exitstatus != 0
          # TODO ssh verification of install.sh before running arbtrary code would be nice?
          @@install_sh_cache[install_msi_url] ||= Net::HTTP.get(URI(install_msi_url))
          machine.create_dir(provider, File.dirname(install_msi_path))
          machine.write_file(provider, install_msi_path, @@install_msi_cache[install_msi_url])
          machine.execute(provider, "msiexec /qn /i #{escape(install_msi_path)}")
        end
      end

      def converge(provider, machine)
        machine.execute(provider, 'chef-client')
      end

      protected

      def escape(string)
        machine.escape(string)
      end
    end
  end
end
