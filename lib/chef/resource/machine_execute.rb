require 'chef/resource/lwrp_base'
require 'chef_metal'
require 'chef_metal/machine'
require 'chef_metal/driver'

class Chef::Resource::MachineExecute < Chef::Resource::LWRPBase
  self.resource_name = 'machine_execute'

  def initialize(*args)
    super
    @chef_server = run_context.cheffish.current_chef_server
  end

  actions :run
  default_action :run

  attribute :command, :kind_of => String, :name_attribute => true
  attribute :machine, :kind_of => String

  attribute :chef_server, :kind_of => Hash
  attribute :driver, :kind_of => ChefMetal::Driver
end
