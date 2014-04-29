require 'chef_metal/chef_run_data'
require 'chef_metal/chef_run_listener'
require 'chef/resource_collection'

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
      @chef_metal ||= begin
        run_data = ChefMetal::ChefRunData.new
        events.register(ChefMetal::ChefRunListener.new(self))
        run_data
      end
    end
  end

  Chef::Client.when_run_starts do |run_status|
    # Pulling on cheffish_run_data makes it initialize right now
    run_status.run_context.chef_metal
  end

  # Make sure ResourceCollection has insert_at
  class ResourceCollection
    if !method_defined?(:insert_at)
      def insert_at(index, *resources)
        resources.each do |resource|
          is_chef_resource(resource)
        end
        @resources.insert(index, *resources)
        # update name -> location mappings and register new resource
        @resources_by_name.each_key do |key|
          @resources_by_name[key] += resources.size if @resources_by_name[key] >= index
        end
        resources.each_with_index do |resource, i|
          @resources_by_name[resource.to_s] = index + i
        end
      end
    end
  end
end
