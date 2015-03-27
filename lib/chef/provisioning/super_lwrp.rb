require 'chef/resource/lwrp_base'

class Chef
  module Provisioning
    class SuperLWRP < Chef::Resource::LWRPBase
      def initalize(*args)
        super

        # Handle initial values
        self.class.attributes.each do |name, options|
          if options.has_key?(:initial_value)
            initial_value = options[:initial_value]
            initial_value = instance_eval(&initial_value) if initial_value.is_a?(DelayedEvaluator)
            # Initial value procs may return NO_VALUE to indicate that they
            # don't want the initial value to be set (so that defaults can take
            # over later and so they don't have to set it to `nil`--which many
            # attributes don't even support).
            if initial_value != NO_VALUE
              initial_value = validate_attribute_value(name, options[:initial_value], options)
              public_send(name, initial_value)
            end
          end
        end
      end

      def self.declare_resource(load_provider: true)
        self.resource_name = self.dsl_name
        require "chef/provider/#{self.resource_name}" if load_provider
      end

      def self.attributes
        # Handle inheritance
        @attributes ||= self == SuperLWRP ? {} : super.dup
      end

      NOT_PASSED = Object.new.tap do
        def self.to_s
          "NOT_PASSED"
        end
      end
      NO_VALUE = Object.new.tap do
        def self.to_s
          "NO_VALUE"
        end
      end

      def is_set?(attr_name)
        instance_variable_defined?(attr_name)
      end

      #
      # Add lazy defaults, ability to set `nil`, :initial_value, :must_be and :coerce validation_opts to `attribute`
      #
      def self.attribute(attr_name, options={})
        attributes[attr_name] = options

        #
        # Turn all validation options into must_be and must_not_be
        #
        must_be = options.has_key?(:must_be) ? [options[:must_be]].flatten : nil
        must_be += [options[:kind_of]].flatten if options.has_key?(:kind_of)
        must_be += [options[:equal_to]].flatten if options.has_key?(:equal_to)
        must_be += [options[:regex]].flatten if options.has_key?(:regex)
        must_be += [options[:respond_to]].flatten.map { |name| proc { |v| v.respond_to?(name) } } if options.has_key?(:respond_to)
        options[:must_be] = must_be if must_be

        must_not_be = options.has_key?(:must_not_be) ? [options[:must_not_be]].flatten : nil
        must_not_be += [options[:cannot_be]].flatten.map { |name| proc { |v| !(v.respond_to(name) && v.send(name)) } } if options.has_key?(:cannot_be)
        options[:must_not_be] = must_not_be if must_not_be

        instance_variable_name = "@@#{attr_name}"

        define_method(attr_name) do |value=NOT_PASSED|
          if value == NOT_PASSED
            #
            # Get the value
            #
            if instance_variable_defined?(instance_variable_name)
              value = instance_variable_get(instance_variable_name)
            else
              value = options[:default]
            end

            #
            # Unwrap lazy values and coerce/validate them
            #
            if value.is_a?(DelayedEvaluator)
              value = instance_eval(&value)
              value = validate_attribute_value(value, options)
            end

            value

          else

            #
            # Unless it's lazy, coerce and validate the value at set time
            #
            unless value.is_a?(DelayedEvaluator)
              value = validate_attribute_value(value, options)
            end

            #
            # Set the value
            #
            instance_variable_set(instance_variable_name, value)
          end
        end
        define_method(:"#{attr_name}=") do |arg|
          send(attr_name, arg)
        end
      end

      # FUUUUUU cloning
      def load_prior_resource(*args)
        Chef::Log.debug "Overloading #{self.resource_name} load_prior_resource with NOOP"
      end

      protected

      def validate_attribute_value(attr_name, value, options)
        value = instance_exec(value, &options[:coerce]) if options.has_key?(:coerce)
        if options[:must_be] && !options[:must_be].any? { |must_be| must_be === value }
          raise Exceptions::ValidationFailed, "Attribute #{attr_name} value #{value} is not valid: must be one of #{options[:must_be].inspect}"
        end
        value
      end

    end
  end
end
