require 'chef/provisioning/vagrant_driver/driver'

with_driver 'vagrant'

vagrant_box node['chef-metal-driver']['vagrant']['box']['name'] do
  url node['chef-metal-driver']['vagrant']['box']['url']
end
