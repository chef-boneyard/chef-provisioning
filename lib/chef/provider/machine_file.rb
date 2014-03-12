require 'chef/provider/lwrp_base'
require 'cheffish/cheffish_server_api'
require 'chef_metal/action_handler'

class Chef::Provider::MachineFile < Chef::Provider::LWRPBase

  include ProviderActionHandler

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

  action :upload do
    if new_resource.content
      machine.write_file(self, new_resource.path, new_resource.content)
    else
      machine.upload_file(self, new_resource.local_path, new_resource.path)
    end
  end

  action :download do
    machine.download_file(provider, new_resource.path, new_resource.local_path)
  end

  action :delete do
    machine.delete_file(self, new_resource.path)
  end
end
