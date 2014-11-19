require 'chef/provisioning/fog_driver/driver'

with_driver 'aws'

with_machine_options :bootstrap_options => {
  :key_name => 'chef_default'
}
