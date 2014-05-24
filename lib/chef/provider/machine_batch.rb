require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef_metal/chef_provider_action_handler'
require 'chef_metal/add_prefix_action_handler'

class Chef::Provider::MachineBatch < Chef::Provider::LWRPBase

  def action_handler
    @action_handler ||= ChefMetal::ChefProviderActionHandler.new(self)
  end

  use_inline_resources

  def whyrun_supported?
    true
  end

  def parallelizer
    @parallelizer ||= Chef::ChefFS::Parallelizer.new(new_resource.max_simultaneous || 100)
  end

  action :allocate do
    by_new_driver.each do |driver, specs_and_options|
      driver.allocate_machines(action_handler, specs_and_options, parallelizer) do |machine_spec|
        machine_spec.save(action_handler)
      end
    end
  end

  action :ready do
    with_ready_machines
  end

  action :setup do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{m[:resource].name}] ")
      machine[:machine].setup_convergence(prefixed_handler)
      m[:spec].save(action_handler)
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:resource].files)
    end
  end

  action :converge do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{m[:resource].name}] ")
      m[:machine].setup_convergence(prefixed_handler)
      m[:spec].save(action_handler)
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:resource].files)
      m[:machine].converge(prefixed_handler)
      m[:spec].save(action_handler)
    end
  end

  action :stop do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.stop_machines(action_handler, specs_and_options, parallelizer)
    end
  end

  action :destroy do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.destroy_machines(action_handler, specs_and_options, parallelizer)
    end
  end

  def with_ready_machines
    action_allocate
    by_id = @machines.inject({}) { |hash,m| hash[m[:spec].id] = m; hash }
    parallel_do(by_new_driver) do |driver, specs_and_options|
      driver.ready_machines(action_handler, specs_and_options, parallelizer) do |machine|
        machine.machine_spec.save(action_handler)

        m = by_id[machine.machine_spec.id]

        m[:machine] = machine
        begin
          yield m if block_given?
        ensure
          machine.disconnect
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

  def by_new_driver
    result = {}
    @machines.each do |m|
      if m[:resource].driver
        driver = run_context.chef_metal.driver_for(m[:resource].driver)
        result[driver] ||= {}
        result[driver][m[:spec]] = m[:options]
      end
    end
    result
  end

  def by_current_driver
    result = {}
    @machines.each do |m|
      if m[:spec].driver_url
        driver = run_context.chef_metal.driver_for_url(m[:spec].driver_url)
        result[driver] ||= {}
        result[driver][m[:spec]] = m[:options]
      end
    end
    result
  end

  def load_current_resource
    # Load nodes in parallel
    @machines = parallel_do(new_resource.machines) do |machine_resource|
      provider = Chef::Provider::Machine.new(machine_resource, machine_resource.run_context)
      provider.load_current_resource
      {
        :resource => machine_resource,
        :spec => provider.machine_spec,
        :options => provider.machine_options
      }
    end.to_a
  end

end
