require 'chef_metal'
require 'chef/resource/fog_key_pair'
require 'chef/provider/fog_key_pair'
require 'chef_metal_fog/fog_driver'

class Chef
  module DSL
    module Recipe
      def with_fog_driver(options = {}, &block)
        run_context.chef_metal.with_driver(ChefMetalFog::FogDriver.new(options), &block)
      end

      def with_fog_ec2_driver(options = {}, &block)
        with_fog_driver({ :provider => 'AWS' }.merge(options), &block)
      end

      def with_fog_openstack_driver(options = {}, &block)
        with_fog_driver({ :provider => 'OpenStack' }.merge(options), &block)
      end
    end
  end
end
