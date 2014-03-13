require 'chef_metal/convergence_strategy/precreate_chef_objects'
require 'pathname'

module ChefMetal
  class ConvergenceStrategy
    class Bootstrap < PrecreateChefObjects
      @@install_sh_cache = {}

      def initialize(options = {})
        @install_sh_url = options[:install_sh_url] || 'http://www.opscode.com/chef/install.sh'
        @install_sh_path = options[:install_sh_path] || '/tmp/chef-install.sh'
        @client_rb_path ||= '/etc/chef/client.rb'
        @client_pem_path ||= '/etc/chef/client.pem'
      end

      attr_reader :install_sh_url
      attr_reader :install_sh_path

      def setup_convergence(provider, machine, machine_resource)
        puts "BOOTSTRAP PROVIDER:\n\n#{provider}\n\n"
        puts "BOOTSTRAP MACHINE:\n\n#{machine}\n\n"
        puts "BOOTSTRAP MACHINE_RESOURCE:\n\n#{machine_resource}\n\n"
        # super

        # # Install chef-client.  TODO check and update version if not latest / not desired
        # if machine.execute_always('chef-client -v').exitstatus != 0
        #   # TODO ssh verification of install.sh before running arbtrary code would be nice?
        #   @@install_sh_cache[install_sh_url] ||= Net::HTTP.get(URI(install_sh_url))
        #   machine.write_file(provider, install_sh_path, @@install_sh_cache[install_sh_url], :ensure_dir => true)
        #   machine.execute(provider, "bash #{install_sh_path}")
        # end
      end

      def converge(provider, machine)
        machine.execute(provider, 'chef-client')
      end
    end
  end
end
