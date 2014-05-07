require 'chef_metal'
require 'chef_metal_lxc/lxc_driver'
with_driver ChefMetalLXC::LXCProvisioner.new
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
with_machine_options 'template' => 'ubuntu', 'template_options'=>['-r','precise']
with_chef_server "http://#{node.ipaddress}:8889"
