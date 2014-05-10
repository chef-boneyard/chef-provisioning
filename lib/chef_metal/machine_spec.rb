require 'chef_metal'
require 'cheffish'
require 'cheffish/cheffish_server_api'

module ChefMetal
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineSpec
    def initialize(node, chef_server)
      @node = node
      @chef_server = chef_server
    end

    #
    # Get a MachineSpec from the chef server.
    #
    def self.get(name, chef_server)
      if !chef_server
        raise "No chef server passed to MachineSpec.get(name)"
      end
      chef_api = Cheffish::CheffishServerAPI.new(chef_server)
      MachineSpec.new(chef_api.get("/nodes/#{name}"), chef_server)
    end

    attr_reader :node
    attr_reader :chef_server

    #
    # Globally unique identifier for this machine. Does not depend on the machine's
    # location or existence.
    #
    def id
      MachineSpec.id_from(chef_server, name)
    end

    def self.id_from(chef_server, name)
      "#{chef_server[:chef_server_url]}/nodes/#{name}"
    end

    #
    # Name of the machine. Corresponds to the name in "machine 'name' do" ...
    #
    def name
      @node['name']
    end

    #
    # Location of this machine. This should be a freeform hash, with enough
    # information for the driver to look it up and create a Machine object to
    # access it.
    #
    # This MUST include a 'driver_url' attribute with the driver's URL in it.
    #
    # chef-metal will do its darnedest to not lose this information.
    #
    def location
      metal_attr('location')
    end

    #
    # Set the location for this machine.
    #
    def location=(value)
      set_metal_attr('location', value)
    end

    # URL to the driver.  Convenience for location['driver_url']
    def driver_url
      location ? location['driver_url'] : nil
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save(action_handler)
      # Save the node to the server.
      _self = self
      ChefMetal.inline_resource(action_handler) do
        chef_node _self.name do
          chef_server _self.chef_server
          raw_json _self.node
        end
      end
    end

    #
    # Chef API object for the given Chef server
    #
    def chef_api
      Cheffish::CheffishServerAPI.new(@chef_server)
    end

    private

    def metal_attr(attr)
      if @node['normal'] && @node['normal']['metal']
        @node['normal']['metal'][attr]
      else
        nil
      end
    end

    def set_metal_attr(attr, value)
      @node['normal'] ||= {}
      @node['normal']['metal'] ||= {}
      @node['normal']['metal'][attr] = value
    end
  end
end
