require 'chef_metal/lxc'
with_provisioner ChefMetal::Provisioner::LXC.new
with_provisioner_options 'template' => 'ubuntu'
