module IronChef
  class BootstrapperBase
    def machine_context(recipe_context, name)
      raise "machine_context(recipe_context, name) not defined on #{self.class}"
    end
  end
end
