require 'chef/log'
require 'fog/aws'

#   fog:AWS:<account_id>:<region>
#   fog:AWS:<profile_name>
#   fog:AWS:<profile_name>:<region>
module ChefMetalFog
  module Providers
    class AWS < ChefMetalFog::FogDriver

      require_relative 'aws/credentials'

      ChefMetalFog::FogDriver.register_provider_class('AWS', ChefMetalFog::Providers::AWS)

      def creator
        driver_options[:aws_account_info][:aws_username]
      end

      def default_ssh_username
        'ubuntu'
      end

      def bootstrap_options_for(action_handler, machine_spec, machine_options)
        bootstrap_options = symbolize_keys(machine_options[:bootstrap_options] || {})

        unless !bootstrap_options[:key_name]
          bootstrap_options[:key_name] = overwrite_default_key_willy_nilly(action_handler)
        end

        bootstrap_options[:tags]  = default_tags(machine_spec, bootstrap_options[:tags] || {})

        bootstrap_options[:name] ||= machine_spec.name

        bootstrap_options
      end

      def self.get_aws_profile(driver_options, aws_account_id)
        aws_credentials = get_aws_credentials(driver_options)
        compute_options = driver_options[:compute_options] || {}

        # Order of operations:
        # compute_options[:aws_access_key_id] / compute_options[:aws_secret_access_key] / compute_options[:aws_security_token] / compute_options[:region]
        # compute_options[:aws_profile]
        # ENV['AWS_ACCESS_KEY_ID'] / ENV['AWS_SECRET_ACCESS_KEY'] / ENV['AWS_SECURITY_TOKEN'] / ENV['AWS_REGION']
        # ENV['AWS_PROFILE']
        # ENV['DEFAULT_PROFILE']
        # 'default'
        aws_profile = if compute_options[:aws_access_key_id]
            Chef::Log.debug("Using AWS driver access key options")
            {
              :aws_access_key_id => compute_options[:aws_access_key_id],
              :aws_secret_access_key => compute_options[:aws_secret_access_key],
              :aws_security_token => compute_options[:aws_session_token],
              :region => compute_options[:region]
            }
          elsif driver_options[:aws_profile]
            Chef::Log.debug("Using AWS profile #{driver_options[:aws_profile]}")
            aws_credentials[driver_options[:aws_profile]]
          elsif ENV['AWS_ACCESS_KEY_ID']
            Chef::Log.debug("Using AWS environment variable access keys")
            {
              :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
              :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
              :aws_security_token => ENV['AWS_SECURITY_TOKEN'],
              :region => ENV['AWS_REGION']
            }
          elsif ENV['AWS_PROFILE']
            Chef::Log.debug("Using AWS profile #{ENV['AWS_PROFILE']} from AWS_PROFILE environment variable")
            aws_credentials[ENV['AWS_PROFILE']]
          else
            Chef::Log.debug("Using AWS default profile")
            aws_credentials.default
          end

        # Merge in account info for profile
        if aws_profile
          aws_profile = aws_profile.merge(aws_account_info_for(aws_profile))
        end

        # If no profile is found (or the profile is not the right account), search
        # for a profile that matches the given account ID
        if aws_account_id && (!aws_profile || aws_profile[:aws_account_id] != aws_account_id)
          aws_profile = find_aws_profile_for_account_id(aws_credentials, aws_account_id)
        end

        if !aws_profile
          raise "No AWS profile specified!  Are you missing something in the Chef config or ~/.aws/config?"
        end

        aws_profile.delete_if { |key, value| value.nil? }
        aws_profile
      end

      def self.find_aws_profile_for_account_id(aws_credentials, aws_account_id)
        aws_profile = nil
        aws_credentials.each do |profile_name, profile|
          begin
            aws_account_info = aws_account_info_for(profile)
          rescue
            Chef::Log.warn("Could not connect to AWS profile #{aws_credentials[:name]}: #{$!}")
            Chef::Log.debug($!.backtrace.join("\n"))
            next
          end
          if aws_account_info[:aws_account_id] == aws_account_id
            aws_profile = profile
            aws_profile[:name] = profile_name
            aws_profile = aws_profile.merge(aws_account_info)
            break
          end
        end
        if aws_profile
          Chef::Log.info("Discovered AWS profile #{aws_profile[:name]} pointing at account #{aws_account_id}.  Using ...")
        else
          raise "No AWS profile leads to account ##{aws_account_id}.  Do you need to add profiles to ~/.aws/config?"
        end
        aws_profile
      end

      def self.aws_account_info_for(aws_profile)
        @@aws_account_info ||= {}
        @@aws_account_info[aws_profile[:aws_access_key_id]] ||= begin
          options = {
            :aws_access_key_id => aws_profile[:aws_access_key_id],
            :aws_secret_access_key => aws_profile[:aws_secret_access_key],
            :aws_session_token => aws_profile[:aws_security_token]
          }
          options.delete_if { |key, value| value.nil? }

          iam = Fog::AWS::IAM.new(options)
          arn = begin
                  # TODO it would be nice if Fog let you do this normally ...
                  iam.send(:request, {
                    'Action'    => 'GetUser',
                    :parser     => Fog::Parsers::AWS::IAM::GetUser.new
                  }).body['User']['Arn']
                rescue Fog::AWS::IAM::Error
                  # TODO Someone tell me there is a better way to find out your current
                  # user ID than this!  This is what happens when you use an IAM user
                  # with default privileges.
                  if $!.message =~ /AccessDenied.+(arn:aws:iam::\d+:\S+)/
                    arn = $1
                  else
                    raise
                  end
                end
          arn_split = arn.split(':', 6)
          {
            :aws_account_id => arn_split[4],
            :aws_username => arn_split[5],
            :aws_user_arn => arn
          }
        end
      end

      def self.get_aws_credentials(driver_options)
        # Grab the list of possible credentials
        if driver_options[:aws_credentials]
          aws_credentials = driver_options[:aws_credentials]
        else
          aws_credentials = Credentials.new
          if driver_options[:aws_config_file]
            aws_credentials.load_ini(driver_options.delete(:aws_config_file))
          elsif driver_options[:aws_csv_file]
            aws_credentials.load_csv(driver_options.delete(:aws_csv_file))
          else
            aws_credentials.load_default
          end
        end
        aws_credentials
      end

      def self.compute_options_for(provider, id, config)
        new_compute_options = {}
        new_compute_options[:provider] = provider
        new_config = { :driver_options => { :compute_options => new_compute_options }}
        new_defaults = {
          :driver_options => { :compute_options => {} },
          :machine_options => { :bootstrap_options => {} }
        }
        result = Cheffish::MergedConfig.new(new_config, config, new_defaults)

        if id && id != ''
          # AWS canonical URLs are of the form fog:AWS:
          if id =~ /^(\d{12})(:(.+))?$/
            if $2
              id = $1
              new_compute_options[:region] = $3
            else
              Chef::Log.warn("Old-style AWS URL #{id} from an early beta of chef-metal (before 0.11-final) found. If you have servers in multiple regions on this account, you may see odd behavior like servers being recreated. To fix, edit any nodes with attribute metal.location.driver_url to include the region like so: fog:AWS:#{id}:<region> (e.g. us-east-1)")
            end
          else
            # Assume it is a profile name, and set that.
            aws_profile, region = id.split(':', 2)
            new_config[:driver_options][:aws_profile] = aws_profile
            new_compute_options[:region] = region
            id = nil
          end
        end

        aws_profile = get_aws_profile(result[:driver_options], id)
        new_compute_options[:aws_access_key_id] = aws_profile[:aws_access_key_id]
        new_compute_options[:aws_secret_access_key] = aws_profile[:aws_secret_access_key]
        new_compute_options[:aws_session_token] = aws_profile[:aws_security_token]
        new_defaults[:driver_options][:compute_options][:region] = aws_profile[:region]

        account_info = aws_account_info_for(result[:driver_options][:compute_options])
        new_config[:driver_options][:aws_account_info] = account_info
        id = "#{account_info[:aws_account_id]}:#{result[:driver_options][:compute_options][:region]}"

        [result, id]
      end
    end
  end
end
