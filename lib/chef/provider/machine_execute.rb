require 'chef/provider/lwrp_base'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/machine'

class Chef
class Provider
class MachineExecute < Chef::Provider::LWRPBase

  def action_handler
    @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
  end

  use_inline_resources

  def whyrun_supported?
    true
  end

  def machine
    @machine ||= begin
      if new_resource.machine.kind_of?(Chef::Provisioning::Machine)
        new_resource.machine
      else
        run_context.chef_provisioning.connect_to_machine(new_resource.machine, new_resource.chef_server)
      end
    end
  end

  action :run do
    machine.execute(action_handler, new_resource.command, :stream => new_resource.live_stream,
                                                          :timeout => new_resource.timeout)
  end

end
end
end
