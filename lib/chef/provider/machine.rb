require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef_metal/provider_action_handler'

class Chef::Provider::Machine < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    node_json = node_provider.new_json
    node_json['normal']['provisioner_options'] = new_resource.provisioner_options
    # Preserve provisioner_output, whatever the cost
    node_json['normal']['provisioner_output'] = node_provider.current_json['normal']['provisioner_output']
    machine = new_resource.provisioner.acquire_machine(self, node_json)
    begin
      machine.setup_convergence(self, new_resource)
      upload_files(machine)
      # If we were asked to converge, or anything changed, or if a converge has never succeeded, converge.
      if new_resource.converge || (new_resource.converge.nil? && resource_updated?) ||
         !node_json['automatic'] || node_json['automatic'].size == 0
        machine.converge(self, new_resource.chef_server)
      end
    ensure
      machine.disconnect
    end
  end

  action :converge do
    node_json = node_provider.new_json
    node_json['normal']['provisioner_options'] = new_resource.provisioner_options
    # Preserve provisioner_output, whatever the cost
    node_json['normal']['provisioner_output'] = node_provider.current_json['normal']['provisioner_output']
    machine = new_resource.provisioner.connect_to_machine(node_json)
    begin
      machine.converge(self, new_resource.chef_server)
    ensure
      machine.disconnect
    end
  end

  action :stop do
    node_json = node_provider.new_json
    node_json['normal']['provisioner_options'] = new_resource.provisioner_options
    # Preserve provisioner_output, whatever the cost
    node_json['normal']['provisioner_output'] = node_provider.current_json['normal']['provisioner_output']
    new_resource.provisioner.stop_machine(self, node_json)
  end

  action :delete do
    # Grab the node json by asking the provider for it
    node_data = node_provider.current_json

    # Destroy the machine
    new_resource.provisioner.delete_machine(self, node_data)
  end

  attr_reader :node_provider

  def load_current_resource
    @node_provider = Chef::Provider::ChefNode.new(new_resource, run_context)
    @node_provider.load_current_resource
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
