require 'chef_metal_fog/fog_provisioner'

ChefMetal.add_registered_provisioner_class("fog",
  ChefMetalFog::FogProvisioner)
