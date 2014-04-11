module ChefMetal
  class ConvergenceStrategy
    def setup_convergence(action_handler, machine, machine_resource)
      raise "setup_convergence not overridden on #{self.class}"
    end

    def converge(action_handler, machine, chef_server)
      raise "converge not overridden on #{self.class}"
    end

    def cleanup_convergence(action_handler, node)
      raise "cleanup_convergence not overridden on #{self.class}"
    end
  end
end
