module ChefMetal
  class Provisioner
    # Inflate a provisioner from node information; we don't want to force the
    # driver to figure out what the provisioner really needs, since it varies
    # from provisioner to provisioner.
    #
    # ## Parameters
    # node - node to inflate the provisioner for
    #
    # returns a should return a Privisoner from the information provided
    def self.inflate(node)
      raise "#{self.class} does not override self.inflate"
    end

    # Acquire a machine, generally by provisioning it.  Returns a Machine
    # object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.  The Machine object will have a
    # "node" property which must be saved to the server (if it is any
    # different from the original node object).
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a provider, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    # node - node object (deserialized json) representing this machine.  If
    #        the node has a provisioner_options hash in it, these will be used
    #        instead of options provided by the provisioner.  TODO compare and
    #        fail if different?
    #        node will have node['normal']['provisioner_options'] in it with any
    #        options. It is a hash with at least these options:
    #
    #           -- provisioner_url: <provisioner url>
    #
    #        node['normal']['provisioner_output'] will be populated with
    #        information about the created machine.  For vagrant, it is a hash
    #        with at least these options:
    #
    #           -- provisioner_url: <provisioner url>
    #
    def acquire_machine(action_handler, node)
      raise "#{self.class} does not override acquire_machine"
    end

    # Connect to a machine without acquiring it.  This method will NOT make any
    # changes to anything.
    #
    # ## Parameters
    # node - node object (deserialized json) representing this machine.  The
    #        node may have normal attributes "provisioner_options" and
    #        "provisioner_output" in it, representing the input and output of
    #        any prior "acquire_machine" process (if any).
    #
    def connect_to_machine(node)
      raise "#{self.class} does not override connect_to_machine"
    end

    # Delete the given machine (idempotent).  Should destroy the machine,
    # returning things to the state before acquire_machine was called.
    def delete_machine(action_handler, node)
      raise "#{self.class} does not override delete_machine"
    end

    # Stop the given machine.
    def stop_machine(action_handler, node)
      raise "#{self.class} does not override stop_machine"
    end

    # Provider notification that happens at the point a resource is declared
    # (after all properties have been set on it)
    def resource_created(machine)
    end

    protected

    def save_node(provider, node, chef_server)
      # Save the node and create the client.  TODO strip automatic attributes first so we don't race with "current state"
      ChefMetal.inline_resource(provider) do
        chef_node node['name'] do
          chef_server chef_server
          raw_json node
        end
      end
    end
  end
end
