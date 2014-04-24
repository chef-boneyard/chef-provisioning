require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'chef_metal/provider_action_handler'
require 'chef/chef_fs/parallelizer'

class Chef::Provider::MachineBatch < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  def parallelizer
    @parallelizer ||= Chef::ChefFS::Parallelizer.new(new_resource.max_simultaneous || 100)
  end

  action :create do
    # Collect nodes by provisioner

    by_provisioner = new_resource.machines.group_by { |machine| machine.provisioner }
    # Talk to each provisioner in parallel
    parallel_do(by_provisioner) do |provisioner, machines|
      nodes_json = machines.map do |machine|
        node_json = node_providers[machine].new_json
        node_json['normal']['provisioner_options'] = machine.provisioner_options
        node_json['normal']['provisioner_options'] = node_providers[machine].current_json['normal']['provisioner_output']
        node_json
      end
      if provisioner.respond_to?(:acquire_machines)
        provisioner.acquire_machines(self, nodes_json)
      else
        # Fall back to just running acquire_machine in parallel
        parallel_do(nodes_json) do |node_json|
          provisioner.acquire_machine(self, node_json)
        end
      end
    end
  end

  def parallel_do(enum, options = {}, &block)
    parallelizer.parallelize(enum, options, &block).to_a
  end


  attr_reader :node_providers

  def load_current_resource
    @node_providers = {}
    new_resource.machines.each do |machine|
      @node_providers[machine] = Chef::Provider::ChefNode.new(machine, nil)
    end
    # Load nodes in parallel
    parallel_do(@node_providers.values) do |node_provider|
      node_provider.load_current_resource
    end
  end

end
