require 'chef_metal'
require 'chef/resource/fog_key_pair'
require 'chef/provider/fog_key_pair'
require 'chef_metal_fog/fog_provisioner'

class Chef
  class Recipe
    def with_fog_provisioner(options = {}, &block)
      run_context.chef_metal.with_provisioner(ChefMetalFog::FogProvisioner.new(options), &block)
    end

    def with_fog_ec2_provisioner(options = {}, &block)
      with_fog_provisioner({ :provider => 'AWS' }.merge(options), &block)
    end

    def with_fog_openstack_provisioner(options = {}, &block)
      with_fog_provisioner({ :provider => 'OpenStack' }.merge(options), &block)
    end
  end
end
