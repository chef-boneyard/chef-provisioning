module ChefMetal
  class ConvergenceStrategy
    # Get the machine ready to converge, but do not converge.
    # options is a hash of setup options, including:
    # - :allow_overwrite_keys
    # - :source_key, :source_key_path, :source_key_pass_phrase
    # - :private_key_options
    # - :ohai_hints
    # - :public_key_path, :public_key_format
    # - :admin, :validator
    def setup_convergence(action_handler, machine, options)
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
