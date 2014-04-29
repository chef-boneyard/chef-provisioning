require 'chef/resource/lwrp_base'

class Chef::Resource::MachineBatch < Chef::Resource::LWRPBase
  self.resource_name = 'machine_batch'

  def initialize(*args)
    super
    @machines = []
    @chef_server = run_context.cheffish.current_chef_server
  end

  # TODO there is a useful action sequence where one does an ohai on all machines,
  # waits for that to complete, save the nodes, and THEN converges.
  actions :acquire, :setup, :converge, :stop, :delete
  default_action :converge

  attribute :machines, :kind_of => [ Array ]
  attribute :max_simultaneous, :kind_of => [ Integer ]
  attribute :chef_server
end
