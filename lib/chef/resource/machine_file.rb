require 'chef/resource/lwrp_base'
require 'chef/provisioning'
require 'chef/provisioning/machine'
require 'chef/provisioning/driver'

class Chef
class Resource
class MachineFile < Chef::Resource::LWRPBase

  self.resource_name = 'machine_file'

  def initialize(*args)
    super
    @chef_server = run_context.cheffish.current_chef_server
  end

  actions :upload, :download, :delete, :nothing
  default_action :upload

  attribute :path, :kind_of => String, :name_attribute => true
  attribute :machine, :kind_of => String, :required => true
  attribute :local_path, :kind_of => String
  attribute :content

  attribute :owner, :kind_of => String
  attribute :group, :kind_of => String
  attribute :mode, :kind_of => String

  attribute :chef_server, :kind_of => Hash
  attribute :driver, :kind_of => Chef::Provisioning::Driver

end
end
end
