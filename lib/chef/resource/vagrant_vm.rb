require 'chef/resource/lwrp_base'
require 'iron_chef/vagrant/vagrant_bootstrapper'
require 'iron_chef/vagrant/vagrant_machine_context'

class Chef::Resource::VagrantVm < Chef::Resource::LWRPBase
  self.resource_name = 'vagrant_vm'

  actions :create, :delete, :suspend, :resume, :nothing
  default_action :create

  attribute :name, :kind_of => String, :name_attribute => true
  attribute :machine_context, :kind_of => IronChef::Vagrant::VagrantMachineContext
  attribute :bootstrap, :kind_of => IronChef::Vagrant::VagrantBootstrapper
end
