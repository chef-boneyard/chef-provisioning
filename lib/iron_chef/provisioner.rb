module IronChef
  class Provisioner
      # Acquire a machine, generally by provisioning it.  Returns a Machine
      # object pointing at the machine, allowing useful actions like setup,
      # converge, execute, file and directory.  The Machine object will have a
      # "node" property which must be saved to the server (if it is any
      # different from the original node object).
      #
      # ## Parameters
      # provider_context - the provider object that is calling this method.
      # node - node object (deserialized json) representing this machine.  If
      #        the node has a provisioner_options hash in it, these will be used
      #        instead of options provided by the provisioner.  TODO compare and
      #        fail if different?
      #        node will have node['provisioner_options'] in it with any options.
      #        It is a hash with at least these options:
      #
      #           -- provisioner_url: <provisioner url>
      #
      #        node['provisioner_output'] will be populated with information
      #        about the created machine.  For vagrant, it is a hash with at least
      #        these options:
      #
      #           -- provisioner_url: <provisioner url>
      #
    def acquire_machine(provider, node)
      raise "#{self.class} does not override acquire_machine"
    end

    def delete_machine(provider, node)
      raise "#{self.class} does not override delete_machine"
    end

    def provisioner_url(provider)
      raise "#{self.class} does not override provisioner_url"
    end
  end
end
