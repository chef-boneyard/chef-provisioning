require 'chef/provisioning/managed_entry'

class Chef
module Provisioning
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineSpec < ManagedEntry
    def initialize(*args)
      super
      data['name'] ||= name
      # Upgrade from metal to chef_provisioning ASAP.
      if data['normal'] && !data['normal']['chef_provisioning'] && data['normal']['metal']
        data['normal']['chef_provisioning'] = data['normal'].delete('metal')
      end
    end

    alias :node :data

    def attrs
      data['normal'] ||= {}
      data['normal']['chef_provisioning'] ||= {}
    end

    #
    # Location of this machine. This should be a freeform hash, with enough
    # information for the driver to look it up and create a Machine object to
    # access it.
    #
    # This MUST include a 'driver_url' attribute with the driver's URL in it.
    #
    # chef-provisioning will do its darnedest to not lose this information.
    #
    def reference
      attrs['reference'] || attrs['location']
    end

    #
    # Set the location for this machine.
    #
    def reference=(value)
      attrs.delete('location')
      attrs['reference'] = value
    end

    alias :location :reference
    alias :location= :reference=

    def from_image
      attrs['from_image']
    end
    def from_image=(value)
      attrs['from_image'] = value
    end
  end
end
end
