require 'chef/resource/lwrp_base'
require 'iron_chef/vagrant/vagrant_bootstrapper'

class Chef::Resource::VagrantCluster < Chef::Resource::LWRPBase
  self.resource_name = 'vagrant_cluster'

  def initialize(*args)
    super
    @vm_config = {}
  end

  actions :create, :delete, :nothing
  default_action :create

  attribute :path, :kind_of => String, :name_attribute => true
  attribute :vm_config, :kind_of => Hash

  def bootstrapper
    IronChef::Vagrant::VagrantBootstrapper.new(path, vm_config)
  end

  def after_created
    super
    IronChef.enclosing_bootstrapper = bootstrapper
  end
end
