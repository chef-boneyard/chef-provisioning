require 'cheffish/with_pattern'

module ChefMetal
  class ChefRunData
    extend Cheffish::WithPattern
    with :provisioner
    with :provisioner_options
    with :machine_batch
  end
end
