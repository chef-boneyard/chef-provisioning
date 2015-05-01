require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'

class Chef
class Provider
class MachineImage < Chef::Provider::LWRPBase

  def action_handler
    @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
  end

  def load_current_resource
  end

  # Get the driver specified in the resource
  def new_driver
    @new_driver ||= run_context.chef_provisioning.driver_for(new_resource.driver)
  end

  def chef_managed_entry_store
    @chef_managed_entry_store ||= Provisioning.chef_managed_entry_store(new_resource.chef_server)
  end

  action :create do
    # Get the image mapping on the server (from name to image-id)
    image_spec = chef_managed_entry_store.get_or_new(:machine_image, new_resource.name)
    if image_spec.reference
      # TODO check for real existence and maybe update
    else
      #
      # Create a new image
      #
      create_image(image_spec, new_resource.machine_options || {})
    end
  end

  action :destroy do
    # Destroy the exemplar machine if it exists
    machine_provider = Chef::Provider::Machine.new(new_resource, run_context)
    machine_provider.action_handler = action_handler
    machine_provider.load_current_resource
    machine_provider.action_destroy

    # Get the image mapping on the server (from name to image-id)
    image_spec = chef_managed_entry_store.get(:machine_image, new_resource.name)

    if image_spec && image_spec.reference
      new_driver.destroy_image(action_handler, image_spec, new_resource.image_options)
      image_spec.delete(action_handler)
    end
  end

  def create_image(image_spec, machine_options)
    # 1. Create the exemplar machine
    machine_provider = Chef::Provider::Machine.new(new_resource, run_context)
    machine_provider.action_handler = action_handler
    machine_provider.load_current_resource
    machine_provider.action_converge

    # 2. Create the image
    machine_options = new_machine_options
    new_driver.allocate_image(action_handler, image_spec, new_image_options,
                              machine_provider.machine_spec, machine_options)
    image_spec.driver_url ||= new_driver.driver_url
    image_spec.from_image ||= new_resource.from_image if new_resource.from_image
    image_spec.run_list   ||= machine_provider.machine_spec.node['run_list']

    # 3. Save the linkage from name -> image id
    image_spec.save(action_handler)

    # 4. Wait for image to be ready
    new_driver.ready_image(action_handler, image_spec, new_image_options)

    machine_provider.action_destroy
  end

  def new_image_options
    @new_image_options ||= (new_resource.image_options || {}).to_hash.dup
  end

  def new_machine_options
    @new_machine_options ||= (new_resource.machine_options || {}).to_hash.dup
  end

end
end
end

require 'chef/provisioning/chef_managed_entry_store'
Chef::Provisioning::ChefManagedEntryStore.type_names_for_backcompat[:machine_image] = "images"
