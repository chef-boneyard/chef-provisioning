require 'chef/resource/lwrp_base'
require 'chef/provisioning'
require 'chef/provisioning/machine'
require 'chef/provisioning/driver'

class Chef
class Resource
class MachineExecute < Chef::Resource::LWRPBase

  self.resource_name = 'machine_execute'

  def initialize(*args)
    super
    @chef_server = run_context.cheffish.current_chef_server
  end

  actions :run
  default_action :run

  attribute :command, :kind_of => String, :name_attribute => true
  attribute :timeout, :kind_of => Integer, :default => 15*60
  attribute :machine, :kind_of => String, :required => true
  attribute :live_stream, :kind_of => [TrueClass,FalseClass], :default => false

  attribute :chef_server, :kind_of => Hash
  attribute :driver, :kind_of => Chef::Provisioning::Driver

end
end
end
