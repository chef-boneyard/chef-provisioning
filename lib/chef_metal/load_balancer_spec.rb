module ChefMetal
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  # TODO: This is pretty similar to image_spec, generalize this.
  class LoadBalancerSpec
    def initialize(load_balancer_data)
      @load_balancer_data = load_balancer_data
    end

    attr_reader :load_balancer_data
    attr_reader :machines

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
      load_balancer_data['id']
    end

    #
    # Location of this machine. This should be a freeform hash, with enough
    # information for the driver to look it up and create a Machine object to
    # access it.
    #
    # This MUST include a 'driver_url' attribute with the driver's URL in it.
    #
    # chef-metal will do its darnedest to not lose this information.
    #
    def location
      load_balancer_data['location']
    end

    #
    # Set the location for this machine.
    #
    def location=(value)
      load_balancer_data['location'] =  value
    end

    def load_balancer_options
      load_balancer_data['load_balancer_options']
    end

    def load_balancer_options=(value)
      load_balancer_data['load_balancer_options'] = value
    end

    # URL to the driver.  Convenience for location['driver_url']
    def driver_url
      location ? location['driver_url'] : nil
    end


    def machines
      load_balancer_data['machines'] || []
    end

    def machines=(value)
      load_balancer_data['machines'] = value
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

    def metal_attr(attr)
      if node['normal'] && node['normal']['metal']
        node['normal']['metal'][attr]
      else
        nil
      end
    end

    def set_metal_attr(attr, value)
      node['normal'] ||= {}
      node['normal']['metal'] ||= {}
      node['normal']['metal'][attr] = value
    end
  end
end
