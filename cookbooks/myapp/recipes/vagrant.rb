require 'cheffish'
require 'chef_metal/vagrant'

# Set up a vagrant cluster (place for vms) in ~/machinetest
vagrant_cluster "#{ENV['HOME']}/machinetest"

directory "#{ENV['HOME']}/machinetest/repo"

with_chef_local_server :chef_repo_path => "#{ENV['HOME']}/machinetest/repo"
