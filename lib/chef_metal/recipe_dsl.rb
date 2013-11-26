require 'chef_metal'

class Chef
  class Recipe
    def with_provisioner(provisioner, &block)
      ChefMetal.with_provisioner(provisioner, &block)
    end

    def with_provisioner_options(provisioner_options, &block)
      ChefMetal.with_provisioner_options(provisioner_options, &block)
    end

    def with_vagrant_cluster(cluster_path, &block)
      ChefMetal.with_vagrant_cluster(cluster_path, &block)
    end

    def with_vagrant_box(box_name, vagrant_options = {}, &block)
      ChefMetal.with_vagrant_box(box_name, vagrant_options, &block)
    end
  end
end
