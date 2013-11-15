require 'chef/resource/lwrp_base'

class Chef::Resource::ChefClientSetup < Chef::Resource::LWRPBase
  self.resource_name = 'chef_client_setup'

  def initialize(*args)
    super
    @client_options = {}
  end

  actions :create, :delete, :nothing
  default_action :create

  attribute :client_name, :kind_of => String, :name_attribute => true
  attribute :client_key, :kind_of => String
  attribute :client_options, :kind_of => Hash
  attribute :machine_context

  def before(&block)
    block ? @before = block : @before
  end
end
