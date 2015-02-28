class Chef
module Provisioning
  #
  # Specification for a managed thing.  Remembers where it was stored, and lets
  # you stuff reference data in it.
  #
  class ManagedEntry
    def initialize(managed_entry_store, resource_type, name, data=nil)
      @managed_entry_store = managed_entry_store
      @resource_type = resource_type
      @name = name
      @data = data || {}
    end

    attr_reader :managed_entry_store
    attr_reader :resource_type
    attr_reader :name
    attr_reader :data

    def attrs
      data
    end

    #
    # Globally unique identifier for this machine. Does not depend on the machine's
    # reference or existence.
    #
    def id
      managed_entry_store.identifier(resource_type, name)
    end

    #
    # Reference to this managed thing.  This should be a freeform hash, with enough
    # information for the driver to look it up and create a Machine object to
    # access it.
    #
    # This MUST include a 'driver_url' attribute with the driver's URL in it.
    #
    # chef-provisioning will do its darnedest to not lose this information.
    #
    def reference
      # Backcompat: old data bags didn't have the "reference" field.  If we have
      # no reference field in the data, and the data bag is non-empty, return
      # the root of the data bag.
      attrs['reference'] || attrs['location'] || (attrs == {} ? nil : attrs)
    end

    #
    # Set the reference for this machine.
    #
    def reference=(value)
      self.attrs['reference'] = value
    end

    # URL to the driver.
    def driver_url
      attrs['driver_url'] || (reference ? reference['driver_url'] : nil)
    end
    def driver_url=(value)
      attrs['driver_url'] = value
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save(action_handler)
      managed_entry_store.save_data(resource_type, name, data, action_handler)
    end

    def delete(action_handler)
      managed_entry_store.delete_data(resource_type, name, action_handler)
    end


    #
    # Subclass interface
    #

    #
    # Get the given data
    #
    # @param resource_type [Symbol] The type of thing to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
    # @param name [String] The unique identifier of the thing to retrieve
    #
    # @return [Hash,Array] The data, or `nil` if the data does not exist.  Will be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
    #
    def get_data(resource_type, name)
      raise NotImplementedError, :delete_data
    end

    #
    # Save the given data
    #
    # @param resource_type [Symbol] The type of thing to save (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet ...)
    # @param name [String] The unique identifier of the thing to save
    # @param data [Hash,Array] The data to save.  Must be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
    #
    def save_data(resource_type, name, data, action_handler)
      raise NotImplementedError, :delete_data
    end

    #
    # Delete the given data
    #
    # @param resource_type [Symbol] The type of thing to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
    # @param name [String] The unique identifier of the thing to delete
    #
    # @return [Boolean] Whether anything was deleted or not.
    #
    def delete_data(resource_type, name, action_handler)
      raise NotImplementedError, :delete_data
    end

    def identifier(resource_type, name)
      raise NotImplementedError, :identifier
    end
  end
end
end
