module ChefMetal
  #
  # A Driver instance represents a place where machines can be created and found,
  # and contains methods to create, delete, start, stop, and find them.
  #
  # For AWS, a Driver instance corresponds to a single account.
  # For Vagrant, it is a directory where VM files are found.
  #
  # == How to Make a Driver
  #
  # To implement a Driver, you must implement the following methods:
  #
  # - initialize(driver_url) - create a new driver with the given URL
  # - driver_url - a URL representing everything unique about your driver.
  #                But NOT credentials.
  # - allocate_machine - ask the driver to allocate a machine to you.
  # - ready_machine - get the machine "ready" - wait for it to be booted and
  #                   accessible (for example, accessible via SSH transport).
  # - stop_machine - stop the machine.
  # - destroy_machine - delete the machine.
  # - connect_to_machine - connect to the given machine.
  #
  # Optionally, you can also implement:
  # - allocate_machines - allocate an entire group of machines.
  # - ready_machines - get a group of machines warm and booted.
  # - stop_machines - stop a group of machines.
  # - destroy_machines - delete a group of machines.
  #
  # Additionally, you must create a file named `chef_metal/driver_init/<scheme>.rb`,
  # where <scheme> is the name of the scheme you chose for your driver_url. This
  # file, when required, must call ChefMetal.add_registered_driver(<scheme>, <class>).
  # The given <class>.from_url(url) will be called with a driver_url.
  #
  # All of these methods must be idempotent - if the work is already done, they
  # just don't do anything.
  #
  class Driver
    #
    # Inflate a driver from a driver URL.
    #
    # == Parameters
    # driver_url - the URL to inflate the driver
    # config - a configuration hash.  See "config" for a list of known keys.
    #
    # == Returns
    # A Driver representing the given driver_url.
    #
    def initialize(driver_url, config)
      @driver_url = driver_url
      @config = config
    end

    #
    # Override this on specific driver classes
    #
    def self.from_url(driver_url, config)
      ChefMetal.from_url(driver_url, config)
    end

    #
    # A URL representing the driver and the place where machines come from.
    # This will be stuffed in machine_spec.location['driver_url'] so that the
    # machine can be reinflated.  URLs must have a unique scheme identifying the
    # driver class, and enough information to identify the place where created
    # machines can be found.  For AWS, this is the account number; for lxc and
    # vagrant, it is the directory in which VMs and containers are.
    #
    # For example:
    # - fog:AWS:123456789012
    # - vagrant:/var/vms
    # - lxc:
    # - docker:
    #
    attr_reader :driver_url

    # A configuration hash.  These keys may be present:
    #   - :driver_options: a driver-defined object containing driver config.
    #   - :private_keys: a hash of private keys, with a "name" and a "value".  Values are either strings (paths) or PrivateKey objects.
    #   - :private_key_paths: a list of paths to directories containing private keys.
    #   - :write_private_key_path: the path to which we write new keys by default.
    #   - :log_level: :debug/:info/:warn/:error/:fatal
    #   - :chef_server_url: url to chef server
    #   - :node_name: username to talk to chef server
    #   - :client_key: path to key used to talk to chef server
    attr_reader :config

    #
    # Driver configuration. Equivalent to config[:driver_options] || {}
    #
    def driver_options
      config[:driver_options] || {}
    end

    #
    # Allocate a machine from the PXE/cloud/VM/container driver.  This method
    # does not need to wait for the machine to boot or have an IP, but it must
    # store enough information in machine_spec.location to find the machine
    # later in ready_machine.
    #
    # If a machine is powered off or otherwise unusable, this method may start
    # it, but does not need to wait until it is started.  The idea is to get the
    # gears moving, but the job doesn't need to be done :)
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a driver, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    #
    # existing_machine - a MachineSpec representing the existing machine (if any).
    #
    # machine_options - a set of options representing the desired provisioning
    #                   state of the machine (image name, bootstrap ssh credentials,
    #                   etc.). This will NOT be stored in the machine_spec, and is
    #                   ephemeral.
    #
    # ## Returns
    #
    # Modifies the passed-in machine_spec.  Anything in here will be saved
    # back after allocate_machine completes.
    #
    def allocate_machine(action_handler, machine_spec, machine_options)
      raise "#{self.class} does not implement allocate_machine"
    end

    #
    # Ready a machine, to the point where it is running and accessible via a
    # transport. This will NOT allocate a machine, but may kick it if it is down.
    # This method waits for the machine to be usable, returning a Machine object
    # pointing at the machine, allowing useful actions like setup, converge,
    # execute, file and directory.
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a driver, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    # machine_spec - MachineSpec representing this machine.
    # machine_options - a set of options representing the desired provisioning
    #                   state of the machine (image name, bootstrap ssh credentials,
    #                   etc.). This will NOT be stored in the machine_spec, and is
    #                   ephemeral.
    #
    # ## Returns
    #
    # Machine object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.
    #
    def ready_machine(action_handler, machine_spec, machine_options)
      raise "#{self.class} does not implement ready_machine"
    end

    #
    # Connect to a machine without allocating or readying it.  This method will
    # NOT make any changes to anything, or attempt to wait.
    #
    # ## Parameters
    # machine_spec - MachineSpec representing this machine.
    #
    # ## Returns
    #
    # Machine object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.
    #
    def connect_to_machine(machine_spec, machine_options)
      raise "#{self.class} does not implement connect_to_machine"
    end

    #
    # Delete the given machine (idempotent).  Should destroy the machine,
    # returning things to the state before allocate_machine was called.
    #
    def destroy_machine(action_handler, machine_spec, machine_options)
      raise "#{self.class} does not implement destroy_machine"
    end

    #
    # Stop the given machine.
    #
    def stop_machine(action_handler, machine_spec, machine_options)
      raise "#{self.class} does not implement stop_machine"
    end

    #
    # Optional interface methods
    #

    #
    # Allocate a set of machines.  This should have the same effect as running
    # allocate_machine on all machine_specs.
    #
    # Drivers do not need to implement this; the default implementation
    # calls acquire_machine in parallel.
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a driver, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    # specs_and_options - a hash of machine_spec -> machine_options representing the
    #                 machines to allocate.
    # parallelizer - an object with a parallelize() method that works like this:
    #
    #   parallelizer.parallelize(specs_and_options) do |machine_spec|
    #     allocate_machine(action_handler, machine_spec)
    #   end.to_a
    #   # The to_a at the end causes you to wait until the parallelization is done
    #
    # This object is shared among other chef-metal actions, ensuring that you do
    # not go over parallelization limits set by the user.  Use of the parallelizer
    # to parallelizer machines is not required.
    #
    # ## Block
    #
    # If you pass a block to this function, each machine will be yielded to you
    # as it completes, and then the function will return when all machines are
    # yielded.
    #
    #   allocate_machines(action_handler, specs_and_options, parallelizer) do |machine_spec|
    #     ...
    #   end
    #
    def allocate_machines(action_handler, specs_and_options, parallelizer)
      parallelizer.parallelize(specs_and_options) do |machine_spec, machine_options|
        allocate_machine(add_prefix(machine_spec, action_handler), machine_spec, machine_options)
        yield machine_spec if block_given?
        machine_spec
      end.to_a
    end

    # Acquire machines in batch, in parallel if possible.
    def ready_machines(action_handler, specs_and_options, parallelizer)
      parallelizer.parallelize(specs_and_options) do |machine_spec, machine_options|
        machine = ready_machine(add_prefix(machine_spec, action_handler), machine_spec, machine_options)
        yield machine if block_given?
        machine
      end.to_a
    end

    # Stop machines in batch, in parallel if possible.
    def stop_machines(action_handler, specs_and_options, parallelizer)
      parallelizer.parallelize(specs_and_options) do |machine_spec, machine_options|
        stop_machine(add_prefix(machine_spec, action_handler), machine_spec)
        yield machine_spec if block_given?
      end.to_a
    end

    # Delete machines in batch, in parallel if possible.
    def destroy_machines(action_handler, specs_and_options, parallelizer)
      parallelizer.parallelize(specs_and_options) do |machine_spec, machine_options|
        destroy_machine(add_prefix(machine_spec, action_handler), machine_spec)
        yield machine_spec if block_given?
      end.to_a
    end

    protected

    def add_prefix(machine_spec, action_handler)
      AddPrefixActionHandler.new(action_handler, "[#{machine_spec.name}] ")
    end
  end
end
