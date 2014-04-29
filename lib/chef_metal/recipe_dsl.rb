require 'chef_metal/chef_run_data'

class Chef
  class Recipe
    def with_provisioner(provisioner, &block)
      run_context.chef_metal.with_provisioner(provisioner, &block)
    end

    def with_provisioner_options(provisioner_options, &block)
      run_context.chef_metal.with_provisioner_options(provisioner_options, &block)
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

    def current_provisioner_options
      run_context.chef_metal.current_provisioner_options
    end

    def add_provisioner_options(options, &block)
      run_context.chef_metal.add_provisioner_options(options, &block)
    end
  end

  class RunContext
    def chef_metal
      @chef_metal ||= ChefMetal::ChefRunData.new
    end
  end
end
