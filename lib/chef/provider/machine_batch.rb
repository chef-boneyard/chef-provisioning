require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef_metal/chef_provider_action_handler'
require 'chef_metal/add_prefix_action_handler'

class Chef::Provider::MachineBatch < Chef::Provider::LWRPBase

  include ChefMetal::ChefProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  def parallelizer
    @parallelizer ||= Chef::ChefFS::Parallelizer.new(new_resource.max_simultaneous || 100)
  end

  action :allocate do
    @by_driver.each do |driver, machines|
      machine_specs = machines.inject({}) { |result, m| result[m[:spec]] = m[:resource].machine_options; result }
      driver.allocate_machines(self, machine_specs, parallelizer)
    end
  end

  action :ready do
    with_ready_machines
  end

  action :setup do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(self, "[#{m[:resource].name}] ")
      machine[:machine].setup_convergence(prefixed_handler, m[:resource])
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:resource].files)
    end
  end

  action :converge do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(self, "[#{m[:resource].name}] ")
      m[:machine].setup_convergence(prefixed_handler, m[:resource])
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:resource].files)
      m[:machine].converge(prefixed_handler)
    end
  end

  action :stop do
    parallel_do(@by_driver) do |driver, machines|
      driver.stop_machines(self, machines.map { |m| m[:spec] }, parallelizer)
    end
  end

  action :delete do
    parallel_do(@by_driver) do |driver, machines|
      driver.delete_machines(self, machines.map { |m| m[:spec] }, parallelizer)
    end
  end

  def with_ready_machines
    action_allocate
    parallel_do(@by_driver) do |driver, machines|
      by_id = machines.inject({}) { |hash,m| hash[m[:spec].id] = m; hash }
      machine_specs = machines.inject({}) { |result, m| result[m[:spec]] = m[:resource].machine_options; result }
      driver.ready_machines(self, machine_specs, parallelizer) do |machine_obj|
        machine = by_id[machine_obj.machine_spec.id]

        machine[:machine] = machine_obj
        begin
          yield machine if block_given?
        ensure
          machine_obj.disconnect
        end
      end
    end
  end

  # TODO in many of these cases, the order of the results only matters because you
  # want to match it up with the input.  Make a parallelize method that doesn't
  # care about order and spits back results as quickly as possible.
  def parallel_do(enum, options = {}, &block)
    parallelizer.parallelize(enum, options, &block).to_a
  end

  def load_current_resource
    # Load nodes in parallel
    @by_driver = parallel_do(new_resource.machines) do |machine_resource|
      provider = Chef::Provider::Machine.new(machine_resource, machine_resource.run_context)
      provider.load_current_resource
      {
        :resource => machine_resource,
        :spec => provider.machine_spec
      }
    end.group_by { |machine| machine[:resource].driver }
  end

end
