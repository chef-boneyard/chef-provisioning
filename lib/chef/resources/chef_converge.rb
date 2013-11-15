require 'chef/resource/lwrp_base'

class Chef::Resource::ChefConverge < Chef::Resource::LWRPBase
  self.resource_name = 'chef_converge'

  actions :converge, :nothing
  default_action :converge

  attribute :machine_context

  def before(&block)
    block ? @before = block : @before
  end
end
