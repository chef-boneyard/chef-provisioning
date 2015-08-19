class Chef
module Provisioning
  class ConvergenceStrategy

    # The purpose of this class is to decore the `converge` method with logic to catch any
    # convergence failure exceptions, log them and then squelch them.  The reason we
    # need this is to prevent 1 provisioned node's converge failing an entire provisioning
    # recipe.
    module IgnoreConvergenceFailure

      attr_accessor :ignore_failures_array, :ignore_exit_values

      # This module is only meant to be extended into instances, not classes or modules.
      # Different machines may have different settings so we don't want to extend
      # every `install_sh` strategy with this logic.
      def self.extended(instance)
        opts = instance.convergence_options[:ignore_failure]
        instance.ignore_failures_array = []
        instance.ignore_exit_values = []
        if opts == true
          instance.ignore_failures_array << RuntimeError
        else
          # We assume it is integers or errors
          opts = [opts].flatten
          opts.each do |o|
            case
            when o.is_a?(Fixnum)
              instance.ignore_exit_values << o
            when o.is_a?(Range)
              instance.ignore_exit_values += o.to_a
            when o <= Exception
              instance.ignore_failures_array << o
            end
          end
        end
      end

      def converge(action_handler, machine)
        super
      rescue SystemExit => e
        if ignore_exit_values.include? e.status
          action_handler.performed_action("Caught SystemExit error #{e.status} from converging node but ignoring it")
        else
          raise
        end
      rescue *ignore_failures_array
        action_handler.performed_action("Caught error '#{$!.inspect.gsub(/\n/,'\\n')}' from converging node but ignoring it")
      end

    end

  end
end
end
