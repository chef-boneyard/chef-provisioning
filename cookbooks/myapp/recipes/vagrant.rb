require 'chef_metal_vagrant'

# Set up a vagrant cluster (place for vms) in ~/machinetest
vagrant_cluster "#{ENV['HOME']}/machinetest"
