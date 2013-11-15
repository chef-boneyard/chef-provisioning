require 'iron_chef/machine_context_resources_base'

module IronChef
  module Vagrant
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
        resource = recipe_context.vagrant_vm(machine_context.name, &block)
        resource.machine_context machine_context
        resource
      end
    end
  end
end