include_recipe 'myapp::require_provisioning'

with_driver 'azure'

# Create a Chef server specific to this cluster that still has access to existing cookbooks
with_chef_local_server chef_repo_path: [
  File.join(Chef::Config.chef_repo_path, "azure_repo"),
  Chef::Config.chef_repo_path,
  File.join(Chef::Config.chef_repo_path, "vendored")
]

with_machine_options(
  bootstrap_options: {
    cloud_service_name: 'jkeisercloudtest',
    storage_account_name: 'jkeiserstorage',
    #:vm_size => "A7"
    location: 'West US'
  },
  #:image_id => 'foobar',
  password: 'chefm3t4l\m/'
)
