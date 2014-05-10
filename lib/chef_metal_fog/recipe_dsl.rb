require 'chef_metal_fog/fog_driver'

class Chef
  module DSL
    module Recipe
      def with_fog_driver(provider, driver_config = nil, &block)
        driver = ChefMetalFog::FogDriver.from_provider(provider, driver_config, run_context.config)
        run_context.chef_metal.with_driver(driver, &block)
      end

      def with_fog_ec2_driver(driver_config = nil, &block)
        with_fog_driver('AWS', driver_config, &block)
      end

      def with_fog_openstack_driver(driver_config = nil, &block)
        with_fog_driver('OpenStack', driver_config, &block)
      end
    end
  end
end
