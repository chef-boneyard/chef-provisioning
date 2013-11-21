require 'iron_chef'

class Chef
  class Recipe
    def with_provisioner(provisioner, &block)
      IronChef.with_provisioner(provisioner, &block)
    end

    def with_vagrant_cluster(cluster_path, &block)
      IronChef.with_vagrant_cluster(cluster_path, &block)
    end

    def with_vagrant_box(box_name, vagrant_options = {}, &block)
      IronChef.with_vagrant_box(box_name, vagrant_options, &block)
    end

    def with_vagrant_options(vagrant_options, &block)
      IronChef.with_vagrant_options(vagrant_options, &block)
    end
  end
end
