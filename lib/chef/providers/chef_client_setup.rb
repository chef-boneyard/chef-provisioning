require 'chef/provider/lwrp_base'

class Chef::Provider::ChefClientSetup < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    if new_resource.before
      new_resource.before.call(new_resource)
    end

    on_machine = new_resource.machine_context.resources(self)

    # Create directory
    on_machine.directory new_resource.machine_context.configuration_path

    # Upload private key
    key_path = ::File.join(new_resource.machine_context.configuration_path, "#{new_resource.client_name}.pem")

    on_machine.file key_path do
      content new_resource.client_key
    end

    # Create client.rb file
    client_rb = "node_name '#{new_resource.client_name}'\nclient_key '#{key_path}'\n"
    new_resource.client_options.each_pair do |name, value|
      client_rb << "#{name} #{value.inspect}\n"
    end

    on_machine.file ::File.join(new_resource.machine_context.configuration_path, 'client.rb') do
      content client_rb
    end

    # Install chef-client
    on_machine.execute 'curl -L https://www.opscode.com/chef/install.sh | sudo bash' do
      only_if { new_resource.machine_context.execute('chef-client -v').exitstatus != 0 }
    end
  end

  action :delete do
    # TODO uninstall chef-client
    on_machine.file ::File.join(new_resource.machine_context.configuration_path, 'client.rb') do
      action :delete
    end
    on_machine.file ::File.join(new_resource.machine_context.configuration_path, "#{client_name}.pem") do
      action :delete
    end
  end

  def load_current_resource
    # This is basically a meta-resource; the inner resources do all the heavy lifting
  end
end
