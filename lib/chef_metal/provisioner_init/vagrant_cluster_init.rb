require 'chef_metal/provisioner/vagrant_provisioner'

ChefMetal.add_registered_provisioner("vagrant_cluster",
  ChefMetal::Provisioner::VagrantProvisioner)
