class Chef
module Provisioning
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  # TODO: This is pretty similar to image_spec, generalize this.
  class LoadBalancerSpec
    def initialize(load_balancer_data)
      @load_balancer_data = load_balancer_data
      # Upgrade from metal to chef_provisioning ASAP.
      if @load_balancer_data['normal'] && !@load_balancer_data['normal']['chef_provisioning'] && @load_balancer_data['normal']['metal']
        @load_balancer_data['normal']['chef_provisioning'] = @load_balancer_data['normal'].delete('metal')
      end
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
    # chef-provisioning will do its darnedest to not lose this information.
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
  end
end
