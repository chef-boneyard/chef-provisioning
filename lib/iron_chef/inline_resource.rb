module IronChef
  class InlineResource
    def initialize(provider)
      @provider = provider
    end

    attr_reader :provider

    def run_context
      provider.run_context
    end

    def method_missing(method_symbol, *args, &block)
      # Stolen ruthlessly from Chef's chef/dsl/recipe.rb

      # Checks the new platform => short_name => resource mapping initially
      # then fall back to the older approach (Chef::Resource.const_get) for
      # backward compatibility
      resource_class = Chef::Resource.resource_for_node(method_symbol, provider.run_context.node)

      super unless resource_class
      raise ArgumentError, "You must supply a name when declaring a #{method_symbol} resource" unless args.size > 0

      # If we have a resource like this one, we want to steal its state
      args << run_context
      resource = resource_class.new(*args)
      resource.source_line = caller[0]
      resource.load_prior_resource
      resource.cookbook_name = provider.cookbook_name
      resource.recipe_name = @recipe_name
      resource.params = @params
      # Determine whether this resource is being created in the context of an enclosing Provider
      resource.enclosing_provider = provider.is_a?(Chef::Provider) ? provider : nil
      # Evaluate resource attribute DSL
      resource.instance_eval(&block) if block

      # Run optional resource hook
      resource.after_created

      # Do NOT put this in the resource collection.
      #run_context.resource_collection.insert(resource)

      # Instead, run the action directly.
      Array(resource.action).each do |action|
        resource.updated_by_last_action(false)
        run_provider_action(resource.provider_for_action(action))
        provider.new_resource.updated_by_last_action(true) if resource.updated_by_last_action?
      end
      resource
    end

    # Do Chef::Provider.run_action, but without events
    def run_provider_action(inline_provider)
      if !inline_provider.whyrun_supported?
        raise "#{inline_provider} is not why-run-safe.  Only why-run-safe resources are supported in inline_resource."
      end

      # Blatantly ripped off from chef/provider run_action

      # TODO: it would be preferable to get the action to be executed in the
      # constructor...

      # user-defined LWRPs may include unsafe load_current_resource methods that cannot be run in whyrun mode
      inline_provider.load_current_resource
      inline_provider.define_resource_requirements
      inline_provider.process_resource_requirements

      # user-defined providers including LWRPs may
      # not include whyrun support - if they don't support it
      # we can't execute any actions while we're running in
      # whyrun mode. Instead we 'fake' whyrun by documenting that
      # we can't execute the action.
      # in non-whyrun mode, this will still cause the action to be
      # executed normally.
      if inline_provider.whyrun_supported? && !inline_provider.requirements.action_blocked?(@action)
        inline_provider.send("action_#{inline_provider.action}")
      elsif !inline_provider.whyrun_mode?
        inline_provider.send("action_#{inline_provider.action}")
      end

      if inline_provider.resource_updated?
        inline_provider.new_resource.updated_by_last_action(true)
      end

      inline_provider.cleanup_after_converge
    end
  end
end