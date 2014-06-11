require 'chef_metal_fog/fog_driver'

#   fog:AWS:<account_id>:<region>
#   fog:AWS:<profile_name>
#   fog:AWS:<profile_name>:<region>
module ChefMetalFog
  module Drivers
    class AWS < ChefMetalFog::FogDriver

      def creator
        driver_options[:aws_account_info][:aws_username]
      end

      def ssh_username
        'ubuntu'
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

        aws_profile = FogDriverAWS.get_aws_profile(result[:driver_options], id)
        new_compute_options[:aws_access_key_id] = aws_profile[:aws_access_key_id]
        new_compute_options[:aws_secret_access_key] = aws_profile[:aws_secret_access_key]
        new_compute_options[:aws_session_token] = aws_profile[:aws_security_token]
        new_defaults[:driver_options][:compute_options][:region] = aws_profile[:region]

        account_info = FogDriverAWS.aws_account_info_for(result[:driver_options][:compute_options])
        new_config[:driver_options][:aws_account_info] = account_info
        id = "#{account_info[:aws_account_id]}:#{result[:driver_options][:compute_options][:region]}"

        [result, id]
      end

    end
  end
end
