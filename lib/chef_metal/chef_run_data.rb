require 'cheffish/with_pattern'
require 'chef/mixin/deep_merge'

module ChefMetal
  class ChefRunData
    extend Cheffish::WithPattern
    with :driver
    with :machine_options
    with :machine_batch

    def add_machine_options(options, &block)
      if current_machine_options
        with_machine_options(Chef::Mixin::DeepMerge.hash_only_merge(current_machine_options, options), &block)
      else
        with_machine_options(options)
      end
    end
  end
end
