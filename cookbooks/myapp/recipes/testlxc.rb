TestHelper.install_latest_gem(self, 'chef-metal-fog', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal-vagrant', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'lxc-extra', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal-lxc', '/tmp/packages_from_host')

require 'chef_metal'
require 'chef_metal_lxc/lxc_provisioner'
with_provisioner ChefMetalLXC::LXCProvisioner.new
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
#with_provisioner_options 'template' => 'ubuntu',
#                         'template_options'=>['-r','precise'],
#                         'config_file' => '/tmp/empty.conf',
#                         'extra_config' => { 'lxc.network.type' => 'empty' }
with_provisioner_options 'template' => 'download', 'template_options'=>['-d','ubuntu','-r','precise','-a','amd64']
file '/tmp/empty.conf' do
  content ''
end
machine 'simple'
