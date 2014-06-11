require 'chef_metal_fog/fog_driver'
module ChefMetalFog
  module Drivers
    class Rackspace < ChefMetalFog::FogDriver

      def creator
        compute_options[:rackspace_username]
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

        new_compute_options[:rackspace_auth_url] = id if (id && id != '')
        credential = Fog.credentials

        new_compute_options[:rackspace_username] ||= credential[:rackspace_username]
        new_compute_options[:rackspace_api_key] ||= credential[:rackspace_api_key]
        new_compute_options[:rackspace_auth_url] ||= credential[:rackspace_auth_url]
        new_compute_options[:rackspace_region] ||= credential[:rackspace_region]
        new_compute_options[:rackspace_endpoint] ||= credential[:rackspace_endpoint]

        id = result[:driver_options][:compute_options][:rackspace_auth_url]

        [result, id]
      end

    end
  end
end
