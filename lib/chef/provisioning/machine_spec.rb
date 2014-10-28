class Chef
module Provisioning
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineSpec
    def initialize(node)
      @node = node
      # Upgrade from metal to chef_provisioning ASAP.
      if node['normal'] && !node['normal']['chef_provisioning'] && node['normal']['metal']
        node['normal']['chef_provisioning'] = node['normal'].delete('metal')
      end
    end

    attr_reader :node

    #
    # Globally unique identifier for this machine. Does not depend on the machine's
    # location or existence.
    #
    def id
      raise "id unimplemented"
    end

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

    # URL to the driver.  Convenience for location['driver_url']
    def driver_url
      location ? location['driver_url'] : nil
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save(action_handler)
      raise "save unimplemented"
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
