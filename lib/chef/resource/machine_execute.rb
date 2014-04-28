require 'chef/resource/lwrp_base'
require 'chef_metal'
require 'chef_metal/machine'
require 'chef_metal/provisioner'

class Chef::Resource::MachineExecute < Chef::Resource::LWRPBase
  self.resource_name = 'machine_execute'

  def initialize(*args)
    super
    @chef_server = Cheffish.current_chef_server
    @provisioner = ChefMetal.current_provisioner
  end

  actions :run
  default_action :run

  attribute :command, :kind_of => String, :name_attribute => true
  attribute :machine, :kind_of => [String, ChefMetal::Machine]

  attribute :chef_server, :kind_of => Hash
  attribute :provisioner, :kind_of => ChefMetal::Provisioner
end
