class Chef
module Provisioning
  class ConvergenceStrategy
    # convergence_options - a freeform hash of options to the converger.
    # config - a Chef::Config-like object with global config like :log_level
    def initialize(convergence_options, config)
      @convergence_options = convergence_options || {}
      @config = config
    end

    attr_reader :convergence_options
    attr_reader :config

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
end
