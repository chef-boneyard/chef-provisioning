require 'chef/resource/lwrp_base'

class Chef::Resource::MachineBatch < Chef::Resource::LWRPBase
  self.resource_name = 'machine_batch'

  def initialize(*args)
    super
    @machines = []
    @chef_server = Cheffish.enclosing_chef_server
  end

  actions :create, :setup, :converge, :stop
  default_action :create

  attribute :machines, :kind_of => [ Array ]
  attribute :max_simultaneous, :kind_of => [ Integer ]
  attribute :chef_server
end
