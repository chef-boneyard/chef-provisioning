require 'chef/provider/lwrp_base'

class Chef::Provider::ChefConverge < Chef::Provider::LWRPBase

  def whyrun_supported?
    true
  end

  action :converge do
    if new_resource.before
      new_resource.before.call(new_resource)
    end
    converge_by("converge #{new_resource.machine_context.name}") do
      new_resource.machine_context.converge
    end
  end

  def load_current_resource
    # This is basically a meta-resource; the inner resources do all the heavy lifting
  end
end
