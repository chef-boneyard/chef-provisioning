require 'chef/provisioning/convergence_strategy/precreate_chef_objects'
require 'pathname'
require 'fileutils'
require 'digest/md5'
require 'thread'
require 'chef/http/simple'

class Chef
module Provisioning
  class ConvergenceStrategy
    class InstallCached < PrecreateChefObjects
      # convergence_options is a hash of setup convergence_options, including:
      # - :chef_server
      # - :allow_overwrite_keys
      # - :source_key, :source_key_path, :source_key_pass_phrase
      # - :private_key_options
      # - :ohai_hints
      # - :public_key_path, :public_key_format
      # - :admin, :validator
      # - :chef_client_timeout
      # - :client_rb_path, :client_pem_path
      # - :chef_version, :prerelease, :package_cache_path
      # - :package_metadata
      def initialize(convergence_options, config)
        convergence_options = Cheffish::MergedConfig.new(convergence_options, {
          :client_rb_path => '/etc/chef/client.rb',
          :client_pem_path => '/etc/chef/client.pem'
        })
        super(convergence_options, config)
        @client_rb_path ||= convergence_options[:client_rb_path]
        @chef_version ||= convergence_options[:chef_version]
        @prerelease ||= convergence_options[:prerelease]
        @package_cache_path ||= convergence_options[:package_cache_path] || "#{ENV['HOME']}/.chef/package_cache"
        @package_cache = {}
        @tmp_dir = '/tmp'
        @chef_client_timeout = convergence_options.has_key?(:chef_client_timeout) ? convergence_options[:chef_client_timeout] : 120*60 # Default: 2 hours
        FileUtils.mkdir_p(@package_cache_path)
        @package_cache_lock = Mutex.new
        @package_metadata ||= convergence_options[:package_metadata]
      end

      attr_reader :client_rb_path
      attr_reader :client_pem_path
      attr_reader :chef_version
      attr_reader :prerelease

      def setup_convergence(action_handler, machine)
        super

        # Check for existing chef client.
        version = machine.execute_always('chef-client -v')

        # Don't do install/upgrade if a chef client exists and
        # no chef version is defined by user configs or
        # the chef client's version already matches user config
        if version.exitstatus == 0
          version = version.stdout.strip
          if !chef_version
            return
          elsif version =~ /Chef: #{chef_version}$/
            Chef::Log.debug "Already installed chef version #{version}"
            return
          elsif version.include?(chef_version)
            Chef::Log.warn "Installed chef version #{version} contains desired version #{chef_version}.  " +
              "If you see this message on consecutive chef runs tighten your desired version constraint to prevent " +
              "multiple convergence."
          end
        end

        # Install chef client
        platform, platform_version, machine_architecture = machine.detect_os(action_handler)
        package_file = download_package_for_platform(action_handler, machine, platform, platform_version, machine_architecture)
        remote_package_file = "#{@tmp_dir}/#{File.basename(package_file)}"
        machine.upload_file(action_handler, package_file, remote_package_file)
        install_package(action_handler, machine, platform, remote_package_file)
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
            metadata = @package_metadata
            if !metadata
              Chef::Log.info("No metadata supplied, downloading it...")
              metadata = download_metadata_for_platform(machine, platform, platform_version, machine_architecture)
            end

            # Download actual package desired by metadata
            package_file = "#{@package_cache_path}/#{URI(metadata[:url]).path.split('/')[-1]}"

            Chef::Log.debug("Package metadata: #{metadata}")
            Chef::Provisioning.inline_resource(action_handler) do
              remote_file package_file do
                source metadata[:url]
                checksum metadata[:sha256]
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
        metadata_url="https://www.chef.io/chef/metadata"
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
        metadata_str = Chef::HTTP::Simple.new(uri).get(uri)
        metadata = {}
        metadata_str.each_line do |line|
          key, value = line.split("\t", 2)
          metadata[key.to_sym] = value.chomp
        end
        metadata
      end

      def install_package(action_handler, machine, platform, remote_package_file)
        extension = File.extname(remote_package_file)
        result = case extension
        when '.rpm'
          if platform == "wrlinux"
            machine.execute(action_handler, "yum install -yv \"#{remote_package_file}\"")
          else
            machine.execute(action_handler, "rpm -Uvh --oldpackage --replacepkgs \"#{remote_package_file}\"")
          end
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
end
