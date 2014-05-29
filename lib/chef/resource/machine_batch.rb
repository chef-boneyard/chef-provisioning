require 'chef/resource/lwrp_base'
require 'chef/mixin/deep_merge'

class Chef::Resource::MachineBatch < Chef::Resource::LWRPBase
  self.resource_name = 'machine_batch'

  def initialize(*args)
    super
    @machines = []
    @driver = run_context.chef_metal.current_driver
    @chef_server = run_context.cheffish.current_chef_server
    @machine_options = run_context.chef_metal.current_machine_options
  end

  actions :allocate, :ready, :setup, :converge, :converge_only, :destroy, :stop
  default_action :converge

  attribute :machines, :kind_of => [ Array ]
  attribute :max_simultaneous, :kind_of => [ Integer ]
  attribute :from_recipe

  # These four attributes are for when you pass names or MachineSpecs to
  # "machines".  Not used for auto-batch or explicit inline machine declarations.
  attribute :driver
  attribute :chef_server
  attribute :machine_options
  attribute :files, :kind_of => [ Array ]

  def machines(*values)
    if values.size == 0
      @machines
    else
      @machines += values.flatten
    end
  end

  def machine(name, &block)
    machines << from_recipe.build_resource(:machine, name, caller[0], &block)
  end

  def add_machine_options(options)
    @machine_options = Chef::Mixin::DeepMerge.hash_only_merge(@machine_options, options)
  end
end
