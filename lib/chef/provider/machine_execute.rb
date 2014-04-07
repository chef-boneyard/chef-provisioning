require 'chef/provider/lwrp_base'
require 'cheffish/cheffish_server_api'

class Chef::Provider::MachineExecute < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  def machine
    @machine ||= begin
      if new_resource.machine.kind_of?(ChefMetal::Machine)
        new_resource.machine
      else
        # TODO this is inefficient, can we cache or something?
        node = Cheffish::CheffishServerAPI.new(new_resource.chef_server).get("/nodes/#{new_resource.machine}")
        new_resource.provisioner.connect_to_machine(node)
      end
    end
  end

  action :run do
    machine.execute(self, new_resource.command)
  end
end
