module ChefMetalFog
  module Providers
    class OpenStack < ChefMetalFog::FogDriver

      ChefMetalFog::FogDriver.register_provider_class('OpenStack', ChefMetalFog::Providers::OpenStack)

      def creator
        compute_options[:openstack_username]
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

        new_compute_options[:openstack_auth_url] = id if (id && id != '')
        credential = Fog.credentials

        new_compute_options[:openstack_username] ||= credential[:openstack_username]
        new_compute_options[:openstack_api_key] ||= credential[:openstack_api_key]
        new_compute_options[:openstack_auth_url] ||= credential[:openstack_auth_url]
        new_compute_options[:openstack_tenant] ||= credential[:openstack_tenant]

        id = result[:driver_options][:compute_options][:openstack_auth_url]

        [result, id]
      end

    end
  end
end
