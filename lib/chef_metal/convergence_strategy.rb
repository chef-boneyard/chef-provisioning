module ChefMetal
  class ConvergenceStrategy
    # TODO machine_resource is needed for private key options. Find a better way.
    def setup_convergence(action_handler, machine, machine_resource)
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
