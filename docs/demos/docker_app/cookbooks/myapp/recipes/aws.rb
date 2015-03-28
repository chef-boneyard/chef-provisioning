include_recipe 'myapp::require_provisioning'

with_driver 'aws'

# Create a Chef server specific to this cluster that still has access to existing cookbooks
with_chef_local_server chef_repo_path: [
  File.join(Chef::Config.chef_repo_path, "aws_repo"),
  Chef::Config.chef_repo_path,
  File.join(Chef::Config.chef_repo_path, "vendored")
]
