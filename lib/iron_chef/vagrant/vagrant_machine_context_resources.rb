module Cheffish
  class VagrantMachineContextResources < MachineContextResourcesBase
    def initialize(machine_context, recipe_context)
      super
    end

    # Create the raw machine, power it up such that it can be connected to.  Should be done in resources added to recipe_context.
    # When this resource succeeds, a connection can be made to the machine so that read_file and chef_client_setup
    # can be run against it.
    #
    # Attributes are the standard resource attributes.
    def raw_machine(&block)
      # Set up vagrant
      recipe_context.directory(machine_context.bootstrapper.base_path, &block)

      resource = recipe_context.file(machine_context.box_file_path, &block)
      resource.content <<EOM
Vagrant.configure("2") do |config|
  config.vm.define #{machine_context.name.inspect} do |machine|
#{machine_context.vm_config_string('machine.vm', '    ')}
  end
end
EOM

      # Run vagrant up
      resource = recipe_context.execute("vagrant up #{machine_context.name}", &block)
      resource.cwd machine_context.bootstrapper.base_path
      resource.only_if { !machine_context.vagrant("status #{machine_context.name}").stdout =~ /^#{machine_context.name}\s+running/ }
      resource
    end

    # file, execute and disconnect are reused from the base and defined in terms of VagrantMachineContext methods

  end
end
