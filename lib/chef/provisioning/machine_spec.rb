require 'chef/provisioning/generic_spec'

class Chef
module Provisioning
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineSpec < GenericSpec
    def initialize(spec_registry, type, name, node)
      super(spec_registry, :machine, name, node)
      node['name'] ||= name
      # Upgrade from metal to chef_provisioning ASAP.
      if node['normal'] && !node['normal']['chef_provisioning'] && node['normal']['metal']
        node['normal']['chef_provisioning'] = node['normal'].delete('metal')
      end
    end

    alias :node :data

    #
    # Name of the machine. Corresponds to the name in "machine 'name' do" ...
    #
    def name
      node['name']
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
    def location
      chef_provisioning_attr('location')
    end

    #
    # Set the location for this machine.
    #
    def location=(value)
      set_chef_provisioning_attr('location', value)
    end

    def from_image
      chef_provisioning_attr('from_image')
    end
    def from_image=(value)
      set_chef_provisioning_attr('from_image', value)
    end

    protected

    def chef_provisioning_attr(attr)
      if node['normal'] && node['normal']['chef_provisioning']
        node['normal']['chef_provisioning'][attr]
      end
    end

    def set_chef_provisioning_attr(attr, value)
      node['normal'] ||= {}
      node['normal']['chef_provisioning'] ||= {}
      node['normal']['chef_provisioning'][attr] = value
    end
  end
end
end
