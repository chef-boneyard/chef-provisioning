TestHelper.install_latest_gem(self, 'chef-metal-fog', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal-vagrant', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal', '/tmp/packages_from_host')
TestHelper.install_latest_gem(self, 'chef-metal-docker', '/tmp/packages_from_host')

require 'chef_metal_docker'

with_provisioner ChefMetalDocker::DockerProvisioner.new

with_provisioner_options 'base_image' => 'ubuntu:precise', 'command' => 'echo true'

execute 'docker pull ubuntu'

machine 'foo'
