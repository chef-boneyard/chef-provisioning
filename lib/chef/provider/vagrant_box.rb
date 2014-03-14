require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'

class Chef::Provider::VagrantBox < Chef::Provider::LWRPBase

  use_inline_resources

  include Chef::Mixin::ShellOut

  def whyrun_supported?
    true
  end

  action :create do
    if !list_boxes.has_key?(new_resource.name)
      if new_resource.url
        converge_by "run 'vagrant box add #{new_resource.name} #{new_resource.url}'" do
          shell_out("vagrant box add #{new_resource.name} #{new_resource.url}").error!
        end
      else
        raise "Box #{new_resource.name} does not exist"
      end
    end
  end

  action :delete do
    if list_boxes.has_key?(new_resource.name)
      converge_by "run 'vagrant box remove #{new_resource.name} #{list_boxes[new_resource.name]}'" do
        shell_out("vagrant box remove #{new_resource.name} #{list_boxes[new_resource.name]}").error!
      end
    end
  end

  def list_boxes
    @list_boxes ||= shell_out("vagrant box list").stdout.lines.inject({}) do |result, line|
      line =~ /^(\S+)\s+\((.+)\)\s*$/
      result[$1] = $2
      result
    end
  end

  def load_current_resource
  end
end
