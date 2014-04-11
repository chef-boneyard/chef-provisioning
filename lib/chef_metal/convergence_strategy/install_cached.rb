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
        @chef_client_timeout = options.has_key?(:chef_client_timeout) ? options[:chef_client_timeout] : 120*60 # Default: 2 hours
        FileUtils.mkdir_p(@package_cache_path)
        @package_cache_lock = Mutex.new
      end

      def setup_convergence(action_handler, machine, machine_resource)
        super

        # Install chef-client.  TODO check and update version if not latest / not desired
        if machine.execute_always('chef-client -v').exitstatus != 0
          platform, platform_version, machine_architecture = machine.detect_os(action_handler)
          package_file = download_package_for_platform(action_handler, machine, platform, platform_version, machine_architecture)
          remote_package_file = "#{@tmp_dir}/#{File.basename(package_file)}"
          machine.upload_file(action_handler, package_file, remote_package_file)
          install_package(action_handler, machine, remote_package_file)
        end
      end

      def converge(action_handler, machine, chef_server)
        super
        
        machine.execute(action_handler, "chef-client -l #{Chef::Config.log_level.to_s}", :stream => true, :timeout => @chef_client_timeout)
      end

      private

      def download_package_for_platform(action_handler, machine, platform, platform_version, machine_architecture)
        @package_cache_lock.synchronize do
          @package_cache ||= {}
          @package_cache[platform] ||= {}
          @package_cache[platform][platform_version] ||= {}
          @package_cache[platform][platform_version][machine_architecture] ||= { :lock => Mutex.new }
        end
        @package_cache[platform][platform_version][machine_architecture][:lock].synchronize do
          if !@package_cache[platform][platform_version][machine_architecture][:file]
            #
            # Grab metadata
            #
            metadata = download_metadata_for_platform(machine, platform, platform_version, machine_architecture)

            # Download actual package desired by metadata
            package_file = "#{@package_cache_path}/#{URI(metadata['url']).path.split('/')[-1]}"

            ChefMetal.inline_resource(action_handler) do
              remote_file package_file do
                source metadata['url']
                checksum metadata['sha256']
              end
            end

            @package_cache[platform][platform_version][machine_architecture][:file] = package_file
          end
        end
        @package_cache[platform][platform_version][machine_architecture][:file]
      end

      def download_metadata_for_platform(machine, platform, platform_version, machine_architecture)
        #
        # Figure out the URL to the metadata
        #
        metadata_url="https://www.opscode.com/chef/metadata"
        metadata_url << "?v=#{@chef_version}"
        metadata_url << "&prerelease=#{@prerelease ? 'true' : 'false'}"
        metadata_url << "&p=#{platform.strip}"
        metadata_url << "&pv=#{platform_version.strip}"
        metadata_url << "&m=#{machine_architecture.strip}"
        use_ssl = true

        # solaris 9 lacks openssl, solaris 10 lacks recent enough credentials - your base O/S is completely insecure, please upgrade
        if platform == 'solaris2' && (platform_version == '5.9' || platform_version == '5.10')
          metadata_url.sub(/^https/, 'http')
          use_ssl = false
        end

        # Download and parse the metadata
        Chef::Log.debug("Getting metadata for machine #{machine.node['name']}: #{metadata_url}")
        uri = URI(metadata_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = use_ssl
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        metadata_str = response.body
        metadata = {}
        metadata_str.each_line do |line|
          key, value = line.split("\t", 2)
          metadata[key] = value
        end
        metadata
      end

      def install_package(action_handler, machine, remote_package_file)
        extension = File.extname(remote_package_file)
        result = case extension
        when '.rpm'
          machine.execute(action_handler, "rpm -Uvh --oldpackage --replacepkgs \"#{remote_package_file}\"")
        when '.deb'
          machine.execute(action_handler, "dpkg -i \"#{remote_package_file}\"")
        when '.solaris'
          machine.write_file(action_handler, "#{@tmp_dir}/nocheck", <<EOM)
conflict=nocheck
action=nocheck
mail=
EOM
          machine.execute(action_handler, "pkgrm -a \"#{@tmp_dir}/nocheck\" -n chef")
          machine.execute(action_handler, "pkgadd -n -d \"#{remote_package_file}\" -a \"#{@tmp_dir}/nocheck\" chef")
        when '.sh'
          machine.execute(action_handler, "sh \"#{remote_package_file}\"")
        else
          raise "Unknown package extension '#{extension}' for file #{remote_package_file}"
        end
      end
    end
  end
end
