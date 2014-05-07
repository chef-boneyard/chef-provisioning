require 'chef/provider/lwrp_base'
require 'cheffish/cheffish_server_api'
require 'chef_metal/chef_provider_action_handler'

class Chef::Provider::MachineExecute < Chef::Provider::LWRPBase

  include ChefMetal::ChefProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  def machine
    @machine ||= begin
      if new_resource.machine.kind_of?(ChefMetal::Machine)
        new_resource.machine
      else
        ChefMetal::MachineSpec.get(new_resource.machine, new_resource.chef_server).connect
      end
    end
  end

  action :run do
    machine.execute(self, new_resource.command)
  end
end
