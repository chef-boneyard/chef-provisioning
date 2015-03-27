require 'chef/provisioning/super_lwrp'

class Chef
  class Provisioning
    class ProvisioningResource < Chef::Provisioning::SuperLWRP

      attribute :driver,      must_be: Chef::Provisioning::Driver,
                coerce:        lazy { |value| (run_context || Chef::Provisioning).driver_for(value) },
                initial_value: lazy { |value| run_context ? run_context.current_driver : NO_VALUE }

      attribute :chef_server, must_be: Hash,
                initial_value: { |value| run_context ? run_context.current_driver : NO_VALUE }

    end
  end
end
