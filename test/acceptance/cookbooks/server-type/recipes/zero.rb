require 'chef/provisioning'

chef_repo_path = File.join(Chef::Config[:chef_repo_path], 'chef-repo')

directory chef_repo_path

with_chef_local_server :chef_repo_path => chef_repo_path
