require 'chef/provider/lwrp_base'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/machine'

class Chef
class Provider
class MachineFile < Chef::Provider::LWRPBase
  provides :machine_file

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

  action :upload do
    if new_resource.content
      machine.write_file(action_handler, new_resource.path, new_resource.content)
    else
      machine.upload_file(action_handler, new_resource.local_path, new_resource.path)
    end

    # At some point hopefully we will define WindowsMachine.set_attributes
    # See https://github.com/chef/chef-provisioning/issues/285 for how to get
    # rid of this unless check
    unless machine.kind_of?(Chef::Provisioning::Machine::WindowsMachine)
      attributes = {}
      attributes[:group] = new_resource.group if new_resource.group
      attributes[:owner] = new_resource.owner if new_resource.owner
      attributes[:mode] = new_resource.mode if new_resource.mode

      machine.set_attributes(action_handler, new_resource.path, attributes)
    end
  end

  action :download do
    machine.download_file(action_handler, new_resource.path, new_resource.local_path)
  end

  action :delete do
    machine.delete_file(action_handler, new_resource.path)
  end

end
end
end
