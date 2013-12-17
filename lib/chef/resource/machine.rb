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

  def after_created
    # Notify the provisioner of this machine's creation
    @provisioner.resource_created(self)
  end

  actions :create, :delete, :stop, :converge, :nothing
  default_action :create

  # Provisioner attributes
  attribute :provisioner
  attribute :provisioner_options

  # Node attributes
  Cheffish.node_attributes(self)

  # Client keys
  # Options to generate private key (size, type, etc.) when the server doesn't have it
  attribute :private_key_options, :kind_of => String

  # Optionally pull the public key out to a file
  attribute :public_key_path, :kind_of => String
  attribute :public_key_format, :kind_of => String

  # If you really want to force the private key to be a certain key, pass these
  attribute :source_key
  attribute :source_key_path, :kind_of => String
  attribute :source_key_pass_phrase

  # Client attributes
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
