require 'chef_metal'

class Chef
  class Recipe
    def with_provisioner(provisioner, &block)
      ChefMetal.with_provisioner(provisioner, &block)
    end

    def with_provisioner_options(provisioner_options, &block)
      ChefMetal.with_provisioner_options(provisioner_options, &block)
    end
  end
end