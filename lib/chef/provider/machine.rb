require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'

class Chef::Provider::Machine < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    node_json = node_provider.new_json
    node_json['normal']['provisioner_options'] = new_resource.provisioner_options
    machine = new_resource.provisioner.acquire_machine(self, node_json)
    begin
      machine.setup_convergence(self, new_resource)
      # If we were asked to converge, or anything changed, or if a converge has never succeeded, converge.
      if new_resource.converge || (new_resource.converge.nil? && new_resource.updated_by_last_action?) ||
         !node['automatic'] || node['automatic'].size == 0
        machine.converge(self)
      end
    ensure
      machine.disconnect
    end
  end

  action :converge do
    node_json = node_provider.new_json
    node_json['normal']['provisioner_options'] = new_resource.provisioner_options
    machine = new_resource.provisioner.connect_to_machine(node_json)
    begin
      machine.converge(self)
    ensure
      machine.disconnect
    end
  end

  action :delete do
    # Grab the node json by asking the provider for it
    node_data = node_provider.current_json

    # Destroy the machine
    new_resource.provisioner.delete_machine(self, node_data)
  end

  attr_reader :node_provider

  def load_current_resource
    @node_provider = Chef::Provider::ChefNode.new(new_resource, nil)
    @node_provider.load_current_resource
  end
end
