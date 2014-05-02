require 'cheffish/with_pattern'
require 'chef/mixin/deep_merge'

module ChefMetal
  class ChefRunData
    extend Cheffish::WithPattern
    with :provisioner
    with :provisioner_options
    with :machine_batch

    def add_provisioner_options(options, &block)
      if current_provisioner_options
        with_provisioner_options(Chef::Mixin::DeepMerge.hash_only_merge(current_provisioner_options, options), &block)
      else
        with_provisioner_options(options)
      end
    end
  end
end
