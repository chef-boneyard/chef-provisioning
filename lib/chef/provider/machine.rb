require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'

class Chef::Provider::Machine < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    machine = new_resource.provisioner.acquire_machine(self, node_provider.new_json, new_resource.provisioner_options)
    begin
      machine.setup_convergence(self, new_resource)
      machine.converge(self) if new_resource.converge
    ensure
      machine.disconnect
    end
  end

  action :converge do
    # TODO find a faster way of doing this than "create plus converge"
    machine = new_resource.provisioner.acquire_machine(self, node_provider.new_json)
    begin
      machine.converge(self)
    ensure
      machine.disconnect
    end
  end

  def create_machine(converge)
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
