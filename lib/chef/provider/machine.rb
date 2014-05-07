require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef_metal/chef_provider_action_handler'
require 'chef_metal/machine_spec'

class Chef::Provider::Machine < Chef::Provider::LWRPBase

  include ChefMetal::ChefProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :allocate do
    new_resource.driver.allocate_machine(self, machine_spec, new_resource.machine_options)
    machine_spec.save(self)
  end

  action :ready do
    action_allocate
    machine = machine_spec.driver.ready_machine(self, machine_spec, new_resource.machine_options)
  end

  action :setup do
    machine = action_ready
    begin
      machine.setup_convergence(self, new_resource)
      upload_files(machine)
    ensure
      machine.disconnect
    end
  end

  action :converge do
    machine = action_ready
    begin
      machine.setup_convergence(self, new_resource)
      upload_files(machine)
      # If we were asked to converge, or anything changed, or if a converge has never succeeded, converge.
      if new_resource.converge || (new_resource.converge.nil? && resource_updated?) ||
         !machine_spec.node['automatic'] || machine_spec.node['automatic'].size == 0
        machine.converge(self)
      end
    ensure
      machine.disconnect
    end
  end

  action :converge_only do
    machine = machine_spec.connect
    begin
      machine.converge(self)
    ensure
      machine.disconnect
    end
  end

  action :stop do
    driver = machine_spec.driver
    if driver
      driver.stop_machine(self, machine_spec)
    end
  end

  action :delete do
    driver = machine_spec.driver
    if driver
      driver.delete_machine(self, machine_spec)
    end
  end

  attr_reader :machine_spec

  def load_current_resource
    node_driver = Chef::Provider::ChefNode.new(new_resource, run_context)
    node_driver.load_current_resource
    json = node_driver.new_json
    json['normal']['metal'] = node_driver.current_json['normal']['metal']
    @machine_spec = ChefMetal::MachineSpec.new(json, new_resource.chef_server)
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
    Machine.upload_files(self, machine, new_resource.files)
  end
end
