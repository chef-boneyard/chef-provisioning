require 'chef/provisioning/managed_entry'

class Chef
module Provisioning
  #
  # Specification for a image. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineImageSpec < ManagedEntry
    alias :location :reference
    alias :location= :reference=

    def from_image
      data['from_image']
    end
    def from_image=(value)
      data['from_image'] = value
    end
    def run_list
      data['run_list']
    end
    def run_list=(value)
      data['run_list'] = value
    end
  end
end
end
