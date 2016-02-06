require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/add_prefix_action_handler'
require 'chef/provisioning/machine_spec'

class Chef
class Provider
class MachineBatch < Chef::Provider::LWRPBase
  provides :machine_batch

  def action_handler
    @action_handler ||= Provisioning::ChefProviderActionHandler.new(self)
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
        m = by_id[machine_spec.id]
        machine_spec.from_image ||= m[:resource].from_image if m[:resource] && m[:resource].from_image
        machine_spec.driver_url ||= driver.driver_url
        machine_spec.save(m[:action_handler])
      end
    end
  end

  action :ready do
    with_ready_machines
  end

  action :setup do
    with_ready_machines do |m|
      m[:machine].setup_convergence(m[:action_handler])
      m[:spec].save(m[:action_handler])
      Chef::Provider::Machine.upload_files(m[:action_handler], m[:machine], m[:files])
    end
  end

  action :converge do
    with_ready_machines do |m|
      m[:machine].setup_convergence(m[:action_handler])
      m[:spec].save(m[:action_handler])
      Chef::Provider::Machine.upload_files(m[:action_handler], m[:machine], m[:files])

      if m[:resource] && m[:resource].converge
        Chef::Log.info("Converging #{m[:spec].name} because 'converge true' is set ...")
        m[:machine].converge(m[:action_handler])
      elsif (!m[:resource] || m[:resource].converge.nil?) && m[:action_handler].locally_updated
        Chef::Log.info("Converging #{m[:spec].name} because the resource was updated ...")
        m[:machine].converge(m[:action_handler])
      elsif !m[:spec].node['automatic'] || m[:spec].node['automatic'].size == 0
        Chef::Log.info("Converging #{m[:spec].name} because it has never been converged (automatic attributes are empty) ...")
        m[:machine].converge(m[:action_handler])
      elsif m[:resource] && m[:resource].converge == false
        Chef::Log.debug("Not converging #{m[:spec].name} because 'converge false' is set.")
      end
    end
  end

  action :converge_only do
    parallel_do(@machines) do |m|
      machine = run_context.chef_provisioning.connect_to_machine(m[:spec])
      machine.converge(m[:action_handler])
    end
  end

  action :destroy do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.destroy_machines(action_handler, specs_and_options, parallelizer)
      specs_and_options.keys.each do |machine_spec|
        machine_spec.delete(action_handler)
      end
    end
  end

  action :stop do
    parallel_do(by_current_driver) do |driver, specs_and_options|
      driver.stop_machines(action_handler, specs_and_options, parallelizer)
    end
  end

  class MachineBatchError < StandardError
    attr_reader :machine
    def initialize(machine, msg)
      @machine = machine
      super(msg)
    end
  end

  def with_ready_machines
    action_allocate
    parallel_do(by_new_driver) do |driver, specs_and_options|
      driver.ready_machines(action_handler, specs_and_options, parallelizer) do |machine|
        machine.machine_spec.save(action_handler)

        m = by_id[machine.machine_spec.id]

        m[:machine] = machine
        begin
          yield m if block_given?
        rescue StandardError => error
          Chef::Log.debug("Chef provisioning failed on machine #{machine.name}")
          raise MachineBatchError.new(machine, error.message)
        ensure
          machine.disconnect
        end
      end
    end
  end

  def by_id
    @by_id ||= @machines.inject({}) { |hash,m| hash[m[:spec].id] = m; hash }
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
        drivers[m[:desired_driver]] ||= run_context.chef_provisioning.driver_for(m[:desired_driver])
        driver = drivers[m[:desired_driver]]
        # Check whether the current driver is same or different; we disallow
        # moving a machine from one place to another.
        if m[:spec].driver_url
          drivers[m[:spec].driver_url] ||= run_context.chef_provisioning.driver_for(m[:spec].driver_url)
          current_driver = drivers[m[:spec].driver_url]
          if driver.driver_url != current_driver.driver_url
            raise "Cannot move '#{m[:spec].name}' from #{current_driver.driver_url} to #{driver.driver_url}: machine moving is not supported.  Destroy and recreate."
          end
        end
        result[driver] ||= {}
        result[driver][m[:spec]] = m[:machine_options].call(driver)
      else
        raise "No driver specified for #{m[:spec].name}"
      end
    end
    result
  end

  def by_current_driver
    result = {}
    drivers = {}
    @machines.each do |m|
      if m[:spec].driver_url
        drivers[m[:spec].driver_url] ||= run_context.chef_provisioning.driver_for(m[:spec].driver_url)
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
          :resource => machine_resource,
          :spec => provider.machine_spec,
          :desired_driver => machine_resource.driver,
          :files => machine_resource.files,
          :machine_options => proc { |driver| provider.machine_options(driver) },
          :action_handler => Provisioning::AddPrefixActionHandler.new(action_handler, "[#{machine_resource.name}] ")
        }
      elsif machine.is_a?(Provisioning::ManagedEntry)
        machine_spec = machine
        {
          :spec => machine_spec,
          :desired_driver => new_resource.driver,
          :files => new_resource.files,
          :machine_options => proc { |driver| machine_options(driver) },
          :action_handler => Provisioning::AddPrefixActionHandler.new(action_handler, "[#{machine_spec.name}] ")
        }
      else
        name = machine
        machine_spec = chef_managed_entry_store.get_or_new(:machine, name)
        {
          :spec => machine_spec,
          :desired_driver => new_resource.driver,
          :files => new_resource.files,
          :machine_options => proc { |driver| machine_options(driver) },
          :action_handler => Provisioning::AddPrefixActionHandler.new(action_handler, "[#{name}] ")
        }
      end
    end.to_a
  end

  def chef_managed_entry_store
    @chef_managed_entry_store ||= Provisioning.chef_managed_entry_store(new_resource.chef_server)
  end

  def machine_options(driver)
    result = { :convergence_options => { :chef_server => new_resource.chef_server } }
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, run_context.chef_provisioning.config[:machine_options]) if run_context.chef_provisioning.config[:machine_options]
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, driver.config[:machine_options]) if driver.config && driver.config[:machine_options]
    result = Chef::Mixin::DeepMerge.hash_only_merge(result, new_resource.machine_options)
    result
  end

end
end
end
