require 'chef/provider/lwrp_base'

class Chef::Provider::VagrantCluster < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    the_base_path = new_resource.path
    directory new_resource.path
    file ::File.join(new_resource.path, 'Vagrantfile') do
      content <<EOM
Dir.glob('#{::File.join(the_base_path, '*.vm')}') do |vm_file|
  eval(IO.read(vm_file), nil, vm_file)
end
EOM
    end
  end

  action :delete do
    file ::File.join(new_resource.path, 'Vagrantfile') do
      action :delete
    end
    directory new_resource.path do
      action :delete
    end
  end

  def load_current_resource
  end
end
