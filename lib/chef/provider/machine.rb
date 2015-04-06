require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'

class Chef
class Provider
class Machine < Chef::Provider::LWRPBase

  def action_handler
    @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
  end
  def action_handler=(value)
    @action_handler = value
  end

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :allocate do
    if !new_driver
      raise "Driver not specified for machine #{machine_spec.name}"
    end
    if current_driver && current_driver.driver_url != new_driver.driver_url
      raise "Cannot move '#{machine_spec.name}' from #{current_driver.driver_url} to #{new_driver.driver_url}: machine moving is not supported.  Destroy and recreate."
    end
    new_driver.allocate_machine(action_handler, machine_spec, new_machine_options)
    machine_spec.from_image ||= new_resource.from_image if new_resource.from_image
    machine_spec.driver_url ||= new_driver.driver_url
    machine_spec.save(action_handler)
  end

  action :ready do
    action_allocate
    machine = current_driver.ready_machine(action_handler, machine_spec, current_machine_options)
    machine_spec.save(action_handler)
    machine
  end

  action :setup do
    machine = action_ready
    begin
      machine.setup_convergence(action_handler)
      machine_spec.save(action_handler)
      upload_files(machine)
    ensure
      machine.disconnect
    end
  end

  action :converge do
    machine = action_ready
    begin
      machine.setup_convergence(action_handler)
      machine_spec.save(action_handler)
      upload_files(machine)
      # If we were asked to converge, or anything changed, or if a converge has never succeeded, converge.
      if new_resource.converge
        Chef::Log.info("Converging #{machine_spec.name} because 'converge true' is set ...")
        machine.converge(action_handler)
      elsif new_resource.converge.nil? && resource_updated?
        Chef::Log.info("Converging #{machine_spec.name} because the resource was updated ...")
        machine.converge(action_handler)
      elsif !machine_spec.node['automatic'] || machine_spec.node['automatic'].size == 0
        Chef::Log.info("Converging #{machine_spec.name} because it has never been converged (automatic attributes are empty) ...")
        machine.converge(action_handler)
      elsif new_resource.converge == false
        Chef::Log.debug("Not converging #{machine_spec.name} because 'converge false' is set.")
      end
    ensure
      machine.disconnect
    end
  end

  action :converge_only do
    machine = run_context.chef_provisioning.connect_to_machine(machine_spec, current_machine_options)
    begin
      machine.converge(action_handler)
    ensure
      machine.disconnect
    end
  end

  action :stop do
    if current_driver
      current_driver.stop_machine(action_handler, machine_spec, current_machine_options)
    end
  end

  action :destroy do
    if current_driver
      current_driver.destroy_machine(action_handler, machine_spec, current_machine_options)
    end
    machine_spec.delete(action_handler)
  end

  attr_reader :machine_spec

  def new_driver
    run_context.chef_provisioning.driver_for(new_resource.driver)
  end

  def current_driver
    if machine_spec.driver_url
      run_context.chef_provisioning.driver_for(machine_spec.driver_url)
    end
  end

  def from_image_spec
    @from_image_spec ||= begin
      if new_resource.from_image
        chef_managed_entry_store.get!(:machine_image, new_resource.from_image)
      else
        nil
      end
    end
  end

  def new_machine_options
    machine_options(new_driver)
  end

  def current_machine_options
    machine_options(current_driver)
  end

  def machine_options(driver)
    configs = []

    configs << {
      :convergence_options =>
        [ :chef_server,
          :allow_overwrite_keys,
          :source_key, :source_key_path, :source_key_pass_phrase,
          :private_key_options,
          :ohai_hints,
          :public_key_path, :public_key_format,
          :admin, :validator,
          :chef_config
        ].inject({}) do |result, key|
          result[key] = new_resource.send(key)
          result
        end
    }

    configs << new_resource.machine_options if new_resource.machine_options
    configs << driver.config[:machine_options] if driver.config[:machine_options]
    Cheffish::MergedConfig.new(*configs)
  end

  def load_current_resource
    node_driver = Chef::Provider::ChefNode.new(new_resource, run_context)
    node_driver.load_current_resource
    json = node_driver.new_json
    json['normal']['chef_provisioning'] = node_driver.current_json['normal']['chef_provisioning']
    @machine_spec = chef_managed_entry_store.new_entry(:machine, new_resource.name, json)
  end

  def chef_managed_entry_store
    @chef_managed_entry_store ||= Provisioning.chef_managed_entry_store(new_resource.chef_server)
  end

  def self.upload_files(action_handler, machine, files)
    if files
      files.each_pair do |remote_file, local|
        if local.is_a?(Hash)
          if local[:local_path]
            machine.upload_file(action_handler, local[:local_path], remote_file)
          else
            machine.write_file(action_handler, remote_file, local[:content])
          end
        else
          machine.upload_file(action_handler, local, remote_file)
        end
      end
    end
  end

  private

  def upload_files(machine)
    Machine.upload_files(action_handler, machine, new_resource.files)
  end

end
end
end
