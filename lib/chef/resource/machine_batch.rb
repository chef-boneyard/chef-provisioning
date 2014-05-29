require 'chef/resource/lwrp_base'

class Chef::Resource::MachineBatch < Chef::Resource::LWRPBase
  self.resource_name = 'machine_batch'

  def initialize(*args)
    super
    @machines = []
  end

  actions :allocate, :ready, :setup, :converge, :converge_only, :destroy, :stop
  default_action :converge

  attribute :machines, :kind_of => [ Array ]
  attribute :max_simultaneous, :kind_of => [ Integer ]
  attribute :from_recipe

  def machine(name, &block)
    machines << from_recipe.build_resource(:machine, name, caller[0], &block)
  end
end
