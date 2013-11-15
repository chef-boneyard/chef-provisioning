require 'iron_chef/bootstrapper_base'
require 'iron_chef/vagrant/vagrant_machine_context'

module IronChef
  module Vagrant
    class VagrantBootstrapper < BootstrapperBase
      def initialize(base_path, vm_config={})
        @base_path = base_path
        @vm_config = vm_config
      end

      attr_reader :base_path
      attr_reader :vm_config

      def machine_context(name)
        VagrantMachineContext.new(self, name)
      end
    end
  end
end