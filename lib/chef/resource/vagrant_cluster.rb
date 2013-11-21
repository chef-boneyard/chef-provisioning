require 'chef/resource/lwrp_base'
require 'iron_chef/vagrant/vagrant_provisioner'

class Chef::Resource::VagrantCluster < Chef::Resource::LWRPBase
  self.resource_name = 'vagrant_cluster'

  actions :create, :delete, :nothing
  default_action :create

  attribute :path, :kind_of => String, :name_attribute => true

  def after_created
    super
    IronChef.with_vagrant_cluster path
  end
end
