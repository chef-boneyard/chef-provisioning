require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef_metal/provider_action_handler'

class Chef::Provider::MachineBatch < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  def parallelizer
    @parallelizer ||= Chef::ChefFS::Parallelizer.new(new_resource.max_simultaneous || 100)
  end

  action :boot do
    with_booted_machines
  end

  action :setup do
    with_booted_machines do |machine|
      machine[:machine].setup_convergence(self, machine[:resource])
      Chef::Provider::Machine.upload_files(self, machine[:machine], machine[:resource].files)
    end
  end

  action :converge do
    with_booted_machines do |machine|
      machine[:machine].setup_convergence(self, machine[:resource])
      Chef::Provider::Machine.upload_files(self, machine[:machine], machine[:resource].files)
      machine[:machine].converge(self, machine[:resource].chef_server)
    end
  end

  action :stop do
    parallel_do(@by_provisioner) do |provisioner, node_urls|
      provisioner.stop_machines(self, node_urls.map { |n| @by_node[n][:provider].node_provider.current_json }, parallelizer)
    end
  end

  action :delete do
    parallel_do(@by_provisioner) do |provisioner, node_urls|
      provisioner.delete_machines(self, node_urls.map { |n| @by_node[n][:provider].node_provider.current_json }, parallelizer)
    end
  end

  def with_booted_machines
    parallel_do(@by_provisioner) do |provisioner, node_urls|
      machines = node_urls.map do |node_url|
        # Fill in the provisioner options and output in case they got overwritten
        machine = @by_node[node_url]
        machine[:node] = machine[:provider].node_provider.new_json
        machine[:node]['normal']['provisioner_options'] = machine[:resource].provisioner_options
        machine[:node]['normal']['provisioner_output'] = machine[:provider].node_provider.current_json['normal']['provisioner_output']
        machine
      end

      # TODO I don't understand why the object_id hack was necessary.  Using the
      # node as a key didn't work. If we could pass node_urls through acquire_machines,
      # that would solve the problem in a bestest way (nodes themselves are not
      # necessarily unique without knowing the chef_server with which they are
      # associated)
      by_node_json = machines.inject({}) { |result, machine| result[machine[:node].object_id] = machine; result }
      provisioner.acquire_machines(self, by_node_json.values.map { |m| m[:node] }, parallelizer) do |node_json, machine_obj|
        machine = by_node_json[node_json.object_id]

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

  def node_url(machine_resource)
    "#{machine_resource.chef_server[:chef_server_url]}/nodes/#{machine_resource.name}"
  end

  def load_current_resource
    # Figure out which machines are in the batch, remove duplicates, and retrieve
    # the nodes from the Chef server if they exist.
    @by_provisioner = {}
    @by_node = {}
    new_resource.machines.each do |machine_resource|
      next if @by_node.has_key?(node_url(machine_resource))
      next unless Array(machine_resource.action).include?(:create)
      @by_node[node_url(machine_resource)] = {
        :resource => machine_resource,
        :provider => Chef::Provider::Machine.new(machine_resource, nil)
      }
      @by_provisioner[machine_resource.provisioner] ||= []
      @by_provisioner[machine_resource.provisioner] << node_url(machine_resource)
    end
    # Load nodes in parallel
    parallel_do(@by_node.values) do |machine|
      machine[:provider].load_current_resource
    end
  end

end
