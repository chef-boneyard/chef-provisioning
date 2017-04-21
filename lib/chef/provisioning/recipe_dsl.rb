require 'chef/provisioning/chef_run_data'
require 'chef/resource_collection'
require 'chef/resource/chef_data_bag_resource'

require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_batch'
require 'chef/provider/machine_batch'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'
require 'chef/resource/machine_execute'
require 'chef/provider/machine_execute'
require 'chef/resource/machine_image'
require 'chef/provider/machine_image'
require 'chef/resource/load_balancer'
require 'chef/provider/load_balancer'

class Chef
  module DSL
    module Recipe

      def with_driver(driver, options = nil, &block)
        run_context.chef_provisioning.with_driver(driver, options, &block)
      end

      def with_machine_options(machine_options, &block)
        run_context.chef_provisioning.with_machine_options(machine_options, &block)
      end

      def current_machine_options
        run_context.chef_provisioning.current_machine_options
      end

      def add_machine_options(options, &block)
        run_context.chef_provisioning.add_machine_options(options, &block)
      end

      def with_image_options(image_options, &block)
        run_context.chef_provisioning.with_image_options(image_options, &block)
      end

      def current_image_options
        run_context.chef_provisioning.current_image_options
      end

      NOT_PASSED = Object.new

      @@next_machine_batch_index = 0

      def machine_batch_default_name
        @@next_machine_batch_index += 1
        if @@next_machine_batch_index > 1
          "default#{@@next_machine_batch_index}"
        else
          "default"
        end
      end

      def machine_batch(name = nil, &block)
        name ||= machine_batch_default_name
        recipe = self
        declare_resource(:machine_batch, name) do
          from_recipe recipe
          instance_eval(&block)
        end
      end

    end
  end

  class Config
    default(:driver) { ENV['CHEF_DRIVER'] }
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
    def chef_provisioning
      node.run_state[:chef_provisioning] ||= Chef::Provisioning::ChefRunData.new(config)
    end
    alias :chef_metal :chef_provisioning
  end

  class ResourceCollection
    def previous_index
      @insert_after_idx ? @insert_after_idx : @resources.length - 1
    end
  end
end
