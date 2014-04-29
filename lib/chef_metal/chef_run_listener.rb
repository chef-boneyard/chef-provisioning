require 'chef/event_dispatch/base'
require 'chef/resource/machine'
require 'chef/resource/machine_batch'

module ChefMetal
  class ChefRunListener < Chef::EventDispatch::Base
    def initialize(run_context)
      @run_context = run_context
    end

    def converge_start(run_context)
      # Time to insert a default machine batch!
      if @run_context != run_context
        raise "Different run context now :/ Not supposed to happen. Contact developer."
      end

      # Find out what machines are already in batches
      machines_in_machine_batches = {}
      run_context.resource_collection.each do |resource|
        if resource.is_a?(Chef::Resource::MachineBatch)
          resource.machines.each do |machine|
            machines_in_machine_batches[machine] = true
          end
        end
      end

      # Create default machine_batch
      machine_batch = Chef::Resource::MachineBatch.new('default', run_context)
      machine_batch.action :converge
      first_machine_index = nil
      run_context.resource_collection.each_with_index do |resource, i|
        if first_machine_index.nil?
          first_machine_index = i
        end
        if resource.is_a?(Chef::Resource::Machine) && !machines_in_machine_batches.has_key?(resource)
          machine_batch.machines << resource
        end
      end

      # If any unaffiliated machines existed, add the batch to the run
      if !first_machine_index.nil?
        run_context.resource_collection.insert_at(first_machine_index, machine_batch)
      end
    end
  end
end
