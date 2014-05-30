require 'chef_metal_fog/aws_credentials'
require 'chef/log'
require 'fog/aws'

module ChefMetalFog
  module FogDriverAWS
    def self.get_aws_profile(driver_options, compute_options, aws_account_id)
      aws_credentials = get_aws_credentials(driver_options)

      # Grab the given profile
      aws_access_key_id = compute_options[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
      if aws_access_key_id
        aws_profile = aws_credentials.select { |profile| profile[:aws_access_key_id] == aws_access_key_id }.first
        if !aws_profile
          aws_profile = {
            :aws_access_key_id => aws_access_key_id,
            :aws_secret_access_key => compute_options[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY'],
            :aws_security_token => compute_options[:aws_security_token] || ENV['AWS_SECURITY_TOKEN']
          }
        end
        Chef::Log.debug("Using AWS profile #{aws_profile[:name]}")
      elsif driver_options[:aws_profile]
        aws_profile = aws_credentials[driver_options[:aws_profile]]
        if !aws_profile
          raise "AWS profile #{driver_options[:aws_profile]} does not exist! Perhaps your configuration is incorrect?"
        end
        Chef::Log.info("Using AWS profile #{driver_options[:aws_profile]} ...")
      else
        aws_profile = aws_credentials.default
        Chef::Log.info("Using default AWS profile ...")
      end

      # Merge in account info
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

      # Set region
      region = compute_options[:region] || ENV['AWS_DEFAULT_REGION']
      aws_profile[:region] = region if region
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
        aws_credentials = AWSCredentials.new
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
  end
end
