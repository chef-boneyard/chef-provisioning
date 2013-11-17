require 'iron_chef/bootstrapper_base'
require 'iron_chef/vagrant/vagrant_machine_context'

module IronChef
  module Vagrant
    class VagrantBootstrapper < BootstrapperBase
      def initialize(base_path, vagrant_config={}, transport_options={})
        @base_path = base_path
        @vagrant_config = vagrant_config
        @transport_options = transport_options
      end

      attr_reader :base_path
      attr_reader :vagrant_config
      attr_reader :transport_options

      def machine_context(name)
        VagrantMachineContext.new(self, name)
      end
    end
  end
end