require 'mixlib/config'

module ChefMetalTestSuite
  # Nothing to see here
  # See long explanation in the cli.rb file.
  module Config
    extend Mixlib::Config

    config_strict_mode true

    default :server_type, :zero

    default :metal_driver, :vagrant

    default :platform, :ubuntu

    default :platform_version, '14.04'

    default :test_recipes, []

    def self.validate(raise_error = false)
      # future reference https://github.com/opscode/chef/blob/master/lib/chef/mixin/params_validate.rb
      errors = []
      supported_servers = [:zero] #[:zero, :server, :hosted]
      supported_drivers = [:vagrant, :fog, :aws]
      supported_platforms =  {
        :ubuntu => ['10.04', '12.04', '14.04'],
        :centos => ['5', '6', '7'],
        :windows => ['2012']
      }

      # server_type
      errors << "#{server_type} server type not supported. Must be one of #{supported_servers}" unless supported_servers.include?(server_type)

      # driver
      errors << "#{metal_driver} driver not supported. Must be one of #{supported_drivers}" unless supported_drivers.include?(metal_driver)

      # os platform
      errors << "#{platform} plaform not supported. Must be one of #{supported_platforms}" unless supported_platforms.has_key?(platform)

      # os version
      if supported_platforms.has_key?(platform)
        errors << "#{platform_version} platform version not supported for #{platform}. Must be one of #{supported_platforms[platform]}" unless supported_platforms[platform].include?(platform_version)
      end

      if raise_error and !errors.empty?
        raise ArgumentError, "There are configuration errors:\n#{errors.join("\n")}"
      end

      return errors
    end
  end
end
