require 'chef/provisioning/fog_driver/driver'

with_driver 'fog:AWS'

with_machine_options :bootstrap_options => {
  :tags => {
    'chef-provisioning-test' => ''
  }
}
