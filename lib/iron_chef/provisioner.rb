module IronChef
  class Provisioner
    # Acquire a machine, generally by provisioning it.  Returns a Machine
    # object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.  The Machine object will have a
    # "node" property which must be saved to the server (if it is any
    # different from the original node object).
    #
    # This method does 
    # ## Parameters
    # provider - the provider object that is calling this method.
    # node - node object (deserialized json) representing this machine.  If
    #        the node has a vagrant_options hash in it, these will be used
    #        instead of options provided by the provisioner.  TODO compare and
    #        fail if different?
    # provisioner_options - specific options for this machine provider.  These
    #        options will be merged with the existing provider options.
    def acquire_machine(provider, node, provisioner_options)
      raise "#{self.class} does not override acquire_machine"
    end
  end
end
