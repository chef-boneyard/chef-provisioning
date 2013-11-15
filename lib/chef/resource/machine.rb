require 'chef/resource/lwrp_base'
require 'cheffish'
require 'iron_chef'

class Chef::Resource::Machine < Chef::Resource::LWRPBase
  self.resource_name = 'machine'

  def initialize(*args)
    super
    @chef_environment = Cheffish.enclosing_environment
    @bootstrapper = IronChef.enclosing_bootstrapper
  end

  actions :create, :delete, :converge, :nothing
  default_action :create

  Cheffish.node_attributes(self)

  attribute :bootstrapper, :kind_of => Symbol
  attribute :public_key_path, :kind_of => String
  attribute :private_key_path, :kind_of => String
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :validator, :kind_of => [TrueClass, FalseClass]
  attribute :extra_files, :kind_of => Hash

  # chef client version and omnibus
  # chef-zero boot method?
  # chef-client -z boot method?
  # pushy boot method?
end
