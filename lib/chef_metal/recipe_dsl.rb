require 'chef_metal/chef_run_data'
require 'chef/resource_collection'

class Chef
  module DSL
    module Recipe
      def with_driver(driver, &block)
        run_context.chef_metal.with_driver(driver, &block)
      end

      def with_machine_options(machine_options, &block)
        run_context.chef_metal.with_machine_options(machine_options, &block)
      end

      def with_machine_batch(the_machine_batch, options = {}, &block)
        if the_machine_batch.is_a?(String)
          the_machine_batch = machine_batch the_machine_batch do
            if options[:action]
              action options[:action]
            end
            if options[:max_simultaneous]
              max_simultaneous options[:max_simultaneous]
            end
          end
        end
        run_context.chef_metal.with_machine_batch(the_machine_batch, &block)
      end

      def current_machine_options
        run_context.chef_metal.current_machine_options
      end

      def add_machine_options(options, &block)
        run_context.chef_metal.add_machine_options(options, &block)
      end

      # When the machine resource is first declared, create a machine_batch (if there
      # isn't one already)
      def machine(name, &block)
        if !run_context.chef_metal.current_machine_batch
          run_context.chef_metal.with_machine_batch declare_resource(:machine_batch, 'default', caller[0])
        end
        declare_resource(:machine, name, caller[0], &block)
      end
    end
  end

  class Config
    default(:driver) { ENV['CHEF_DRIVER'] }
    config_context :drivers do
      # each key is a driver_url, and each value can have driver, driver_config and machine_options
      config_strict_mode false
    end
    config_context :driver_config do
      # open ended for whatever the driver wants
      config_strict_mode false
    end
    config_context :machine_options do
      # open ended for whatever the driver wants
      config_strict_mode false
    end
    configurable(:private_keys)
    default(:private_key_paths) { [ path_join(config_dir, 'keys'), path_join(user_home, '.ssh') ] }
    default(:private_key_write_path) { private_key_paths.first }
  end

  class RunContext
    def chef_metal
      @chef_metal ||= ChefMetal::ChefRunData.new(config)
    end
  end
end
