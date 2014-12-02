require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/chef_image_spec'

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

  action :create do
    # Get the image mapping on the server (from name to image-id)
    image_spec = Chef::Provisioning::ChefImageSpec.get(new_resource.name, new_resource.chef_server) ||
                 Chef::Provisioning::ChefImageSpec.empty(new_resource.name, new_resource.chef_server)
    if image_spec.location
      # TODO check for real existence and maybe update
    else
      #
      # Create a new image
      #
      image_spec.machine_options = new_resource.machine_options
      create_image(image_spec)
    end
  end

  action :destroy do
  end

  def local_mode?(chef_server_url)
    /^http(s{0,1})\:\/\/(localhost|127.0.0.1)/ === chef_server_url
  end

  def create_image_data_bag_dir(data_bag_path)
    path = "#{::File.expand_path(data_bag_path)}/images"
    unless Dir.exists?(path)
      Dir.mkdir(path)
    end
  end

  def create_image(image_spec)
    # 0. Make sure the images data_bag directory exists
    if local_mode?(run_context.config[:chef_server_url])
      create_image_data_bag_dir(run_context.config[:data_bag_path])
    end

    # 1. Create the exemplar machine
    machine_provider = Chef::Provider::Machine.new(new_resource, run_context)
    machine_provider.load_current_resource
    machine_provider.action_converge

    # 2. Create the image
    new_driver.allocate_image(action_handler, image_spec, new_resource.image_options,
                              machine_provider.machine_spec)

    # 3. Save the linkage from name -> image id
    image_spec.save(action_handler)

    # 4. Wait for image to be ready
    new_driver.ready_image(action_handler, image_spec, new_resource.image_options)
  end

end
end
end