require 'chef/provider/lwrp_base'
require 'chef_metal/provider_action_handler'

class Chef::Provider::VagrantCluster < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    the_base_path = new_resource.path
    ChefMetal.inline_resource(self) do
      directory the_base_path
      file ::File.join(the_base_path, 'Vagrantfile') do
        content <<EOM
Dir.glob('#{::File.join(the_base_path, '*.vm')}') do |vm_file|
  eval(IO.read(vm_file), nil, vm_file)
end
EOM
      end
    end
  end

  action :delete do
    the_base_path = new_resource.path
    ChefMetal.inline_resource(self) do
      file ::File.join(the_base_path, 'Vagrantfile') do
        action :delete
      end
      directory the_base_path do
        action :delete
      end
    end
  end

  def load_current_resource
  end
end
