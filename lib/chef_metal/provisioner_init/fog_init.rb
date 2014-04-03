require 'chef_metal/provisioner/fog_provisioner'

ChefMetal.add_registered_provisioner_class("fog",
  ChefMetal::Provisioner::FogProvisioner)
