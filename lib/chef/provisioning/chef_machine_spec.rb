require 'chef/provisioning'
require 'cheffish'
require 'chef/provisioning/machine_spec'

class Chef
module Provisioning
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class ChefMachineSpec < MachineSpec
    def initialize(node, chef_server)
      super(node)
      @chef_server = chef_server
    end

    #
    # Get a MachineSpec from the chef server.  If the node does not exist on the
    # server, it returns nil.
    #
    def self.get(name, chef_server = Cheffish.default_chef_server)
      chef_api = Cheffish.chef_server_api(chef_server)
      begin
        ChefMachineSpec.new(chef_api.get("/nodes/#{name}"), chef_server)
      rescue Net::HTTPServerException => e
        if e.response.code == '404'
          nil
        else
          raise
        end
      end
    end

    # Creates a new empty MachineSpec with the given name.
    def self.empty(name, chef_server = Cheffish.default_chef_server)
      ChefMachineSpec.new({ 'name' => name, 'normal' => {} }, chef_server)
    end

    #
    # Globally unique identifier for this machine. Does not depend on the machine's
    # location or existence.
    #
    def id
      ChefMachineSpec.id_from(chef_server, name)
    end

    def self.id_from(chef_server, name)
      "#{chef_server[:chef_server_url]}/nodes/#{name}"
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save(action_handler)
      if location && (!location.is_a?(Hash) || !location['driver_url'])
        raise "Drivers must specify a canonical driver_url in machine_spec.location.  Contact your driver's author."
      end
      # Save the node to the server.
      _self = self
      _chef_server = _self.chef_server
      Chef::Provisioning.inline_resource(action_handler) do
        chef_node _self.name do
          chef_server _chef_server
          raw_json _self.node
        end
      end
    end

    protected

    attr_reader :chef_server

    #
    # Chef API object for the given Chef server
    #
    def chef_api
      Cheffish.server_api_for(chef_server)
    end
  end
end
end
