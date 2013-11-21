module IronChef
  class ConvergenceStrategy
    def setup_convergence(provider, machine, machine_resource)
      raise "setup_convergence not overridden on #{self.class}"
    end

    def converge(provider, machine)
      raise "converge not overridden on #{self.class}"
    end

    def delete_chef_objects(provider, node)
      raise "delete_chef_objects not overridden on #{self.class}"
    end
  end
end