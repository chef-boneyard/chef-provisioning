require 'chef/resource/lwrp_base'
require 'chef/mixin/deep_merge'

class Chef
class Resource
class MachineBatch < Chef::Resource::LWRPBase

  self.resource_name = 'machine_batch'

  def initialize(*args)
    super
    @machines = []
    @driver = run_context.chef_provisioning.current_driver
    @chef_server = run_context.cheffish.current_chef_server
    @machine_options = run_context.chef_provisioning.current_machine_options
  end

  actions :allocate, :ready, :setup, :converge, :converge_only, :destroy, :stop, :ready_only
  default_action :converge

  attribute :machines, :kind_of => [ Array ]
  attribute :max_simultaneous, :kind_of => [ Integer ]
  attribute :from_recipe

  # These four attributes are for when you pass names or ManagedEntrys to
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
    machines << from_recipe.build_resource(:machine, name, &block)
  end

  def add_machine_options(options)
    @machine_options = Chef::Mixin::DeepMerge.hash_only_merge(@machine_options, options)
  end

  # We override this because we want to hide @from_recipe and shorten @machines
  # in error output.
  def to_text
    ivars = instance_variables.map { |ivar| ivar.to_sym } - HIDDEN_IVARS - [ :@from_recipe, :@machines ]
    text = "# Declared in #{@source_line}\n\n"
    text << self.class.resource_name.to_s + "(\"#{name}\") do\n"
    ivars.each do |ivar|
      if (value = instance_variable_get(ivar)) && !(value.respond_to?(:empty?) && value.empty?)
        value_string = value.respond_to?(:to_text) ? value.to_text : value.inspect
        text << "  #{ivar.to_s.sub(/^@/,'')} #{value_string}\n"
      end
    end
    machine_names = @machines.map do |m|
      if m.is_a?(Chef::Provisioning::ManagedEntry)
        m.name
      elsif m.is_a?(Chef::Resource::Machine)
        m.name
      else
        m
      end
    end
    text << "  machines #{machine_names.inspect}\n"
    [@not_if, @only_if].flatten.each do |conditional|
      text << "  #{conditional.to_text}\n"
    end
    text << "end\n"
  end

end
end
end
