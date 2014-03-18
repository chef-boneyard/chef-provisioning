require 'chef_metal/convergence_strategy/precreate_chef_objects'
require 'pathname'
require 'fileutils'
require 'digest/md5'
require 'thread'

module ChefMetal
  class ConvergenceStrategy
    class InstallCached < PrecreateChefObjects
      def initialize(options = {})
        @client_rb_path ||= '/etc/chef/client.rb'
        @client_pem_path ||= '/etc/chef/client.pem'
        @chef_version ||= options[:chef_version]
        @prerelease ||= options[:prerelease]
        @package_cache_path ||= options[:package_cache_path] || "#{ENV['HOME']}/.chef/package_cache"
        @package_cache = {}
        @tmp_dir = '/tmp'
        FileUtils.mkdir_p(@package_cache_path)
        @download_lock = Mutex.new
      end

      def setup_convergence(provider, machine, machine_resource)
        super

        # Install chef-client.  TODO check and update version if not latest / not desired
        if machine.execute_always('chef-client -v').exitstatus != 0
          platform, platform_version, machine_architecture = machine.detect_os(provider)
          package_file = download_package_for_platform(provider, machine, platform, platform_version, machine_architecture)
          remote_package_file = "#{@tmp_dir}/#{File.basename(package_file)}"
          machine.upload_file(provider, package_file, remote_package_file)
          install_package(provider, machine, remote_package_file)
        end
      end

      def converge(provider, machine)
        machine.execute(provider, 'chef-client')
      end

      private

      def download_package_for_platform(provider, machine, platform, platform_version, machine_architecture)
        @package_cache ||= {}
        @package_cache[platform] ||= {}
        @package_cache[platform][platform_version] ||= {}
        @package_cache[platform][platform_version][machine_architecture] ||= begin
          @download_lock.synchronize do
            if @package_cache[platform][platform_version][machine_architecture]
              @package_cache[platform][platform_version][machine_architecture]
            else
              #
              # Grab metadata
              #
              metadata = download_metadata_for_platform(machine, platform, platform_version, machine_architecture)

              # Download actual package desired by metadata
              package_file = "#{@package_cache_path}/#{URI(metadata['url']).path.split('/')[-1]}"

              ChefMetal.inline_resource(provider) do
                remote_file package_file do
                  source metadata['url']
                  checksum metadata['sha256']
                end
              end
              package_file
            end
          end
        end
      end

      def download_metadata_for_platform(machine, platform, platform_version, machine_architecture)
        #
        # Figure out the URL to the metadata
        #
        metadata_url="https://www.opscode.com/chef/metadata"
        metadata_url << "?v=#{@chef_version}"
        metadata_url << "&prerelease=#{@prerelease ? 'true' : 'false'}"
        metadata_url << "&p=#{platform}"
        metadata_url << "&pv=#{platform_version}"
        metadata_url << "&m=#{machine_architecture}"

        # solaris 9 lacks openssl, solaris 10 lacks recent enough credentials - your base O/S is completely insecure, please upgrade
        if platform == 'solaris2' && (platform_version == '5.9' || platform_version == '5.10')
          metadata_url.sub(/^https/, 'http')
        end

        # Download and parse the metadata
        Chef::Log.debug("Getting metadata for machine #{machine.node['name']}: #{metadata_url}")
        metadata_str = Net::HTTP.get(URI(metadata_url))
        metadata = {}
        metadata_str.each_line do |line|
          key, value = line.split("\t", 2)
          metadata[key] = value
        end
        metadata
      end

      def install_package(provider, machine, remote_package_file)
        extension = File.extname(remote_package_file)
        result = case extension
        when '.rpm'
          machine.execute(provider, "rpm -Uvh --oldpackage --replacepkgs \"#{remote_package_file}\"")
        when '.deb'
          machine.execute(provider, "dpkg -i \"#{remote_package_file}\"")
        when '.solaris'
          machine.write_file(provider, "#{@tmp_dir}/nocheck", <<EOM)
conflict=nocheck
action=nocheck
mail=
EOM
          machine.execute(provider, "pkgrm -a \"#{@tmp_dir}/nocheck\" -n chef")
          machine.execute(provider, "pkgadd -n -d \"#{remote_package_file}\" -a \"#{@tmp_dir}/nocheck\" chef")
        when '.sh'
          machine.execute(provider, "sh \"#{remote_package_file}\"")
        else
          raise "Unknown package extension '#{extension}' for file #{remote_package_file}"
        end
      end
    end
  end
end
