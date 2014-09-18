require 'chef_metal'
require 'cheffish'
require 'chef_metal/load_balancer_spec'

module ChefMetal
  #
  # Specification for a image. Sufficient information to find and contact it
  # after it has been set up.
  #
  class ChefLoadBalancerSpec < LoadBalancerSpec
    def initialize(node, chef_server)
      super(node)
      @chef_server = chef_server
    end

    #
    # Get a ImageSpec from the chef server.  If the node does not exist on the
    # server, it returns nil.
    #
    def self.get(name, chef_server = Cheffish.default_chef_server)
      chef_api = Cheffish.chef_server_api(chef_server)
      begin
        data = chef_api.get("/data/loadbalancers/#{name}")
        data['load_balancer_options'] = strings_to_symbols(data['load_balancer_options'])
        ChefLoadBalancerSpec.new(data, chef_server)
      rescue Net::HTTPServerException => e
        if e.response.code == '404'
          nil
        else
          raise
        end
      end
    end

    # Creates a new empty ImageSpec with the given name.
    def self.empty(id, chef_server = Cheffish.default_chef_server)
      ChefLoadBalancerSpec.new({ 'id' => id }, chef_server)
    end

    #
    # Globally unique identifier for this image. Does not depend on the image's
    # location or existence.
    #
    def id
      ChefLoadBalancerSpec.id_from(chef_server, name)
    end

    def self.id_from(chef_server, name)
      "#{chef_server[:chef_server_url]}/data/loadbalancers/#{name}"
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_image and ready_image.
    #
    def save(action_handler)
      # Save the node to the server.
      _self = self
      _chef_server = _self.chef_server
      puts "LB SPEC: #{_self.inspect}"
      ChefMetal.inline_resource(action_handler) do
        chef_data_bag_item _self.name do
          data_bag 'loadbalancers'
          chef_server _chef_server
          raw_data _self.load_balancer_data
        end
      end
    end

    def delete(action_handler)
      # Save the node to the server.
      _self = self
      _chef_server = _self.chef_server
      ChefMetal.inline_resource(action_handler) do
        chef_data_bag_item _self.name do
          data_bag 'loadbalancers'
          chef_server _chef_server
          action :destroy
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

    def self.strings_to_symbols(data)
      if data.is_a?(Hash)
        result = {}
        data.each_pair do |key, value|
          result[key.to_sym] = strings_to_symbols(value)
        end
        result
      else
        data
      end
    end
  end
end
