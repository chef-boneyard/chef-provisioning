module ChefMetal
  class ConvergenceStrategy
    def initialize(options)
      @options = options
    end

    attr_reader :options

    # Get the machine ready to converge, but do not converge.
    def setup_convergence(action_handler, machine)
      raise "setup_convergence not overridden on #{self.class}"
    end

    def converge(action_handler, machine)
      raise "converge not overridden on #{self.class}"
    end

    def cleanup_convergence(action_handler, machine_spec)
      raise "cleanup_convergence not overridden on #{self.class}"
    end
  end
end
