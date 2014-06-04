require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef_metal/chef_provider_action_handler'
require 'chef_metal/add_prefix_action_handler'
require 'chef_metal/machine_spec'
require 'chef_metal/chef_machine_spec'

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
        prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{machine_spec.name}] ")
        machine_spec.save(prefixed_handler)
      end
    end
  end

  action :ready do
    with_ready_machines
  end

  action :setup do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{m[:spec].name}] ")
      machine[:machine].setup_convergence(prefixed_handler)
      m[:spec].save(prefixed_handler)
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:files])
    end
  end

  action :converge do
    with_ready_machines do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{m[:spec].name}] ")
      m[:machine].setup_convergence(prefixed_handler)
      m[:spec].save(action_handler)
      Chef::Provider::Machine.upload_files(prefixed_handler, m[:machine], m[:files])
      # TODO only converge if machine was modified
      m[:machine].converge(prefixed_handler)
      m[:spec].save(prefixed_handler)
    end
  end

  action :converge_only do
    parallel_do(@machines) do |m|
      prefixed_handler = ChefMetal::AddPrefixActionHandler.new(action_handler, "[#{m[:spec].name}] ")
      machine = run_context.chef_metal.connect_to_machine(m[:spec])
      machine.converge(prefixed_handler)
    end
  end

  action :destroy do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.destroy_machines(action_handler, specs_and_options, parallelizer)
    end
  end

  action :stop do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.stop_machines(action_handler, specs_and_options, parallelizer)
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
    drivers = {}
    @machines.each do |m|
      if m[:desired_driver]
        drivers[m[:desired_driver]] ||= run_context.chef_metal.driver_for(m[:desired_driver])
        driver = drivers[m[:desired_driver]]
        # Check whether the current driver is same or different; we disallow
        # moving a machine from one place to another.
        if m[:spec].driver_url
          drivers[m[:spec].driver_url] ||= run_context.chef_metal.driver_for(m[:spec].driver_url)
          current_driver = drivers[m[:spec].driver_url]
          if driver.driver_url != current_driver.driver_url
            raise "Cannot move '#{m[:spec].name}' from #{current_driver.driver_url} to #{driver.driver_url}: machine moving is not supported.  Destroy and recreate."
          end
        end
        result[driver] ||= {}
        result[driver][m[:spec]] = m[:machine_options].call(driver)
      end
    end
    result
  end

  def by_current_driver
    result = {}
    drivers = {}
    @machines.each do |m|
      if m[:spec].driver_url
        drivers[m[:spec].driver_url] ||= run_context.chef_metal.driver_for(m[:spec].driver_url)
        driver = drivers[m[:spec].driver_url]
        result[driver] ||= {}
        result[driver][m[:spec]] = m[:machine_options].call(driver)
      end
    end
    result
  end

  def load_current_resource
    # Load nodes in parallel
    @machines = parallel_do(new_resource.machines) do |machine|
      if machine.is_a?(Chef::Resource::Machine)
        machine_resource = machine
        provider = Chef::Provider::Machine.new(machine_resource, machine_resource.run_context)
        provider.load_current_resource
        {
          :spec => provider.machine_spec,
          :desired_driver => machine_resource.driver,
          :files => machine_resource.files,
          :machine_options => proc { |driver| provider.machine_options(driver) }
        }
      elsif machine.is_a?(ChefMetal::MachineSpec)
        machine_spec = machine
        {
          :spec => machine_spec,
          :desired_driver => new_resource.driver,
          :files => new_resource.files,
          :machine_options => proc { |driver| machine_options(driver) }
        }
      else
        name = machine
        machine_spec = ChefMetal::ChefMachineSpec.get(name, new_resource.chef_server) ||
                       ChefMetal::ChefMachineSpec.empty(name, new_resource.chef_server)
        {
          :spec => machine_spec,
          :desired_driver => new_resource.driver,
          :files => new_resource.files,
          :machine_options => proc { |driver| machine_options(driver) }
        }
      end
    end.to_a
  end

  def machine_options(driver)
    result = { :convergence_options => { :chef_server => new_resource.chef_server } }
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, run_context.chef_metal.config[:machine_options]) if run_context.chef_metal.config[:machine_options]
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, driver.config[:machine_options]) if driver.config && driver.config[:machine_options]
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, new_resource.machine_options)
    result
  end
end
