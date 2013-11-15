require 'iron_chef'

class Chef
  class Recipe
    def with_bootstrapper(bootstrapper)
      old_bootstrapper = IronChef.enclosing_bootstrapper
      IronChef.enclosing_bootstrapper = bootstrapper
      if block_given?
        begin
          yield
        ensure
          IronChef.enclosing_bootstrapper = old_bootstrapper
        end
      end
    end
  end
end
