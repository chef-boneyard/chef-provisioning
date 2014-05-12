require 'chef_metal_fog/fog_driver'

class Chef
  module DSL
    module Recipe
      def with_fog_driver(provider, driver_options = nil, &block)
        config = Cheffish::MergedConfig.new({ :driver_options => driver_options }, run_context.config)
        driver = ChefMetalFog::FogDriver.from_provider(provider, config)
        run_context.chef_metal.with_driver(driver, &block)
      end

      def with_fog_ec2_driver(driver_options = nil, &block)
        with_fog_driver('AWS', driver_options, &block)
      end

      def with_fog_openstack_driver(driver_options = nil, &block)
        with_fog_driver('OpenStack', driver_options, &block)
      end
    end
  end
end
