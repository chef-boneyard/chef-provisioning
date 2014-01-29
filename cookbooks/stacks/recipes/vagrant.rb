require 'cheffish'
require 'chef_metal'

repo_base_dir = File.join(File.dirname(__FILE__), '..', '..', '..')
vm_dir =        File.join(repo_base_dir, 'vms')
cluster_repo =  File.join(vm_dir, 'repo')

# Set up a vagrant cluster (place for vms) in ~/machinetest
vagrant_cluster vm_dir

directory cluster_repo
with_chef_local_server :chef_repo_path => cluster_repo
