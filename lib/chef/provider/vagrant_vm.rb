class Chef::Provider::VagrantVm < Chef::Provider::LWRPBase
  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    machine_context = new_resource.machine_context || new_resource.bootstrapper.machine_context(new_resource.name)

    # Set up vagrant
    file machine_context.box_file_path do
      content <<EOM
Vagrant.configure("2") do |config|
  config.vm.define #{machine_context.name.inspect} do |machine|
#{machine_context.vm_config_string('machine.vm', '    ')}
  end
end
EOM
    end

    # Run vagrant up
    execute "vagrant up #{machine_context.name}" do
      cwd machine_context.bootstrapper.base_path
      only_if { machine_context.vagrant("status #{machine_context.name}").stdout !~ /^#{machine_context.name}\s+running/ }
    end
  end

  action :delete do
    machine_context = new_resource.machine_context || new_resource.bootstrapper.machine_context(new_resource.name)

    # TODO make this idempotent
    execute "vagrant destroy -f #{machine_context.name}" do
      cwd machine_context.bootstrapper.base_path
    end

    file machine_context.box_file_path do
      action :delete
    end
  end

  action :suspend do
    machine_context = new_resource.machine_context || new_resource.bootstrapper.machine_context(new_resource.name)

    # TODO make this idempotent
    execute "vagrant suspend #{machine_context.name}" do
      cwd machine_context.bootstrapper.base_path
    end
  end

  action :resume do
    machine_context = new_resource.machine_context || new_resource.bootstrapper.machine_context(new_resource.name)

    # TODO make this idempotent
    execute "vagrant resume #{machine_context.name}" do
      cwd machine_context.bootstrapper.base_path
    end
  end
end
