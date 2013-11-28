require 'chef/resource/lwrp_base'
require 'cheffish'
require 'chef_metal'

class Chef::Resource::Machine < Chef::Resource::LWRPBase
  self.resource_name = 'machine'

  def initialize(*args)
    super
    @chef_environment = Cheffish.enclosing_environment
    @chef_server = Cheffish.enclosing_chef_server
    @provisioner = ChefMetal.enclosing_provisioner
    @provisioner_options = ChefMetal.enclosing_provisioner_options
  end

  actions :create, :delete, :converge, :nothing
  default_action :create

  # Provisioner attributes
  attribute :provisioner, :kind_of => Symbol
  attribute :provisioner_options

  # Node attributes
  Cheffish.node_attributes(self)

  # Client attributes
  attribute :public_key_path, :kind_of => String
  attribute :private_key_path, :kind_of => String
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :validator, :kind_of => [TrueClass, FalseClass]

  # Allows you to turn convergence off in the :create action by writing "converge false"
  # or force it with "true"
  attribute :converge, :kind_of => [TrueClass, FalseClass]

  # chef client version and omnibus
  # chef-zero boot method?
  # chef-client -z boot method?
  # pushy boot method?
end
