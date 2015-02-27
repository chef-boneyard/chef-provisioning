class Chef
module Provisioning
  #
  # Specification for a managed thing.  Remembers where it was stored, and lets
  # you stuff reference data in it.
  #
  class GenericSpec
    def initialize(spec_registry, type, name, data={})
      @spec_registry = spec_registry
      @type = type
      @name = name
      @data = data
    end

    attr_reader :spec_registry
    attr_reader :type
    attr_reader :name
    attr_reader :data

    #
    # Globally unique identifier for this machine. Does not depend on the machine's
    # location or existence.
    #
    def id
      spec_registry.identifier(type, name)
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
      data['location']
    end

    #
    # Set the location for this machine.
    #
    def location=(value)
      self.data['location'] = value
    end

    # URL to the driver.
    def driver_url
      data['driver_url'] || (location ? location['driver_url'] : nil)
    end
    def driver_url=(value)
      data['driver_url'] = value
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save(action_handler)
      spec_registry.save_data(type, name, data, action_handler)
    end

    def delete(action_handler)
      spec_registry.delete_data(type, name, action_handler)
    end
  end
end
end
