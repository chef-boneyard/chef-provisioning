require 'chef/resource/lwrp_base'
require 'chef_metal/vagrant/vagrant_provisioner'

class Chef::Resource::VagrantBox < Chef::Resource::LWRPBase
  self.resource_name = 'vagrant_box'

  actions :create, :delete, :nothing
  default_action :create

  attribute :name, :kind_of => String, :name_attribute => true
  attribute :url, :kind_of => String
  attribute :provisioner_options, :kind_of => Hash

  def after_created
    super
    ChefMetal.with_vagrant_box self
  end
end
