require 'chef_metal/chef_run_data'
require 'chef/resource_collection'

require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_batch'
require 'chef/provider/machine_batch'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'
require 'chef/resource/machine_execute'
require 'chef/provider/machine_execute'

class Chef
  module DSL
    module Recipe
      def with_driver(driver, options = nil, &block)
        run_context.chef_metal.with_driver(driver, options, &block)
      end

      def with_machine_options(machine_options, &block)
        run_context.chef_metal.with_machine_options(machine_options, &block)
      end

      def current_machine_options
        run_context.chef_metal.current_machine_options
      end

      def add_machine_options(options, &block)
        run_context.chef_metal.add_machine_options(options, &block)
      end

      NOT_PASSED = Object.new

      def auto_batch_machines(value = NOT_PASSED)
        if value == NOT_PASSED
          run_context.chef_metal.auto_batch_machines
        else
          run_context.chef_metal.auto_batch_machines = value
        end
      end

      @@next_machine_batch_index = 1

      def machine_batch_default_name
        if @@next_machine_batch_index > 1
          "default#{@@next_machine_batch_index}"
        else
          "default"
        end
        @@next_machine_batch_index += 1
      end

      def machine_batch(name = nil, &block)
        name ||= machine_batch_default_name
        recipe = self
        declare_resource(:machine_batch, name, caller[0]) do
          from_recipe recipe
          instance_eval(&block)
        end
      end

      # When the machine resource is first declared, create a machine_batch (if there
      # isn't one already)
      def machine(name, &block)
        resource = build_resource(:machine, name, caller[0], &block)

        # Grab the previous resource so we can decide whether to batch this or make it its own resource.
        previous_index = run_context.resource_collection.previous_index
        previous = previous_index >= 0 ? run_context.resource_collection[previous_index] : nil
        if run_context.chef_metal.auto_batch_machines &&
           previous &&
           Array(resource.action).size == 1 &&
           Array(previous.action) == Array(resource.action)

          # Handle batching similar machines (with similar actions)
          if previous.is_a?(Chef::Resource::MachineBatch)
            # If we see a machine declared after a previous machine_batch with the same action, add it to the batch.
            previous.machines << resource
          elsif previous.is_a?(Chef::Resource::Machine)
            # If we see two machines in a row with the same action, batch them.
            _self = self
            batch = build_resource(:machine_batch, machine_batch_default_name) do
              action resource.action
              machines [ previous, resource ]
            end
            batch.from_recipe self
            run_context.resource_collection[previous_index] = batch
          else
            run_context.resource_collection.insert(resource)
          end

        else
          run_context.resource_collection.insert(resource)
        end
        resource
      end
    end
  end

  class Config
    default(:driver) { ENV['CHEF_DRIVER'] }
    default(:auto_batch_machines) { true }
  #   config_context :drivers do
  #     # each key is a driver_url, and each value can have driver, driver_options and machine_options
  #     config_strict_mode false
  #   end
  #   config_context :driver_options do
  #     # open ended for whatever the driver wants
  #     config_strict_mode false
  #   end
  #   config_context :machine_options do
  #     # open ended for whatever the driver wants
  #     config_strict_mode false
  #   end
  end

  class RunContext
    def chef_metal
      @chef_metal ||= ChefMetal::ChefRunData.new(config)
    end
  end

  class ResourceCollection
    def previous_index
      @insert_after_idx ? @insert_after_idx : @resources.length - 1
    end
  end
end
