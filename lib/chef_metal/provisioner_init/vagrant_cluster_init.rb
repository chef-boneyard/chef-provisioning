require 'chef_metal/provisioner/vagrant_provisioner'

ChefMetal.add_registered_provisioner_class("vagrant_cluster",
  ChefMetal::Provisioner::VagrantProvisioner)
