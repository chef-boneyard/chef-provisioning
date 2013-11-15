require 'chef/provider/lwrp_base'
require 'openssl'

class Chef::Provider::Machine < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    create_machine(false)
  end

  action :converge do
    create_machine(true)
  end

  def create_machine(converge)
    retrieved_node = nil

    machine_context = new_resource.bootstrapper.machine_context(new_resource.name)

    on_machine = machine_context.resources(self)

    # Create the node
    chef_node new_resource.name do
      chef_environment new_resource.chef_environment
      run_list new_resource.run_list
      default_attributes new_resource.default_attributes
      normal_attributes new_resource.normal_attributes
      override_attributes new_resource.override_attributes
      automatic_attributes new_resource.automatic_attributes
      self.default_modifiers = new_resource.default_modifiers
      self.normal_modifiers = new_resource.normal_modifiers
      self.override_modifiers = new_resource.override_modifiers
      self.automatic_modifiers = new_resource.automatic_modifiers
      self.run_list_modifiers = new_resource.run_list_modifiers
      self.run_list_removers = new_resource.run_list_removers
      complete new_resource.complete
      filter { |node| machine_context.filter_node(node) }

      notifies :converge, on_machine.converge_resource_name
    end

    #
    # Create the machine
    #
    on_machine.raw_machine do
      notifies :converge, on_machine.converge_resource_name
    end

    # Create or update the client
    final_private_key = nil
    chef_client new_resource.name do
      public_key_path new_resource.public_key_path
      private_key_path new_resource.private_key_path
      admin new_resource.admin
      validator new_resource.validator
      key_owner true
      notifies :converge, on_machine.converge_resource_name

      # Pass the private key on the way in
      before do |resource|
        private_key = machine_context.read_file("#{machine_context.configuration_path}/#{new_resource.name}.pem")
        # Verify private key can be parsed
        begin
          OpenSSL::PKey.read(private_key)
        rescue
          private_key = nil
        end
        if private_key
          resource.private_key private_key
        else
          resource.action :regenerate_keys
        end
      end

      # Capture the private key
      after { |resource, json, private_key, public_key| final_private_key = private_key.to_pem }
    end

    #
    # Configure the client
    #
    on_machine.chef_client_setup do
      client_name new_resource.name
      notifies :converge, on_machine.converge_resource_name

      before do |resource|
        resource.client_key final_private_key
      end
    end

    #
    # Upload extra files
    #
    if new_resource.extra_files
      new_resource.extra_files.each do |remote_path, local_path|
        # Unknown files are relative to the configuration path
        remote_path = File.expand_path(remote_path, machine_context.configuration_path)
        on_machine.file remote_path do
          source local_path
          notifies :converge, on_machine.converge_resource_name
        end
      end
    end

    #
    # Converge the client if anything changed
    #
    if converge
      on_machine.chef_converge
    else
      on_machine.chef_converge do
        action :nothing
      end
    end

    #
    # Terminate the machine context (creates a resource that does this)
    #
    on_machine.disconnect
  end

  action :delete do
    begin
      node_json = rest.get("nodes/#{new_resource.name}")
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        node_json = nil
      else
        raise
      end
    end

    if node_json
      on_machine = new_resource.bootstrapper.machine_context(new_resource.name).resources(self)

      # Destroy the machine
      on_machine.raw_machine new_resource.name do
        action :delete
      end

      chef_client new_resource.name do
        action :delete
      end
      chef_node new_resource.name do
        action :delete
      end
    end
  end

  def load_current_resource
    # This is basically a meta-resource; the inner resources do all the heavy lifting
  end
end
