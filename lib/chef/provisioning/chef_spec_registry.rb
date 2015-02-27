require 'chef/provisioning/spec_registry'
require 'cheffish'

class Chef
  module Provisioning
    class ChefSpecRegistry < SpecRegistry
      def initialize(chef_server = Cheffish.default_chef_server)
        @chef_server = chef_server
      end

      attr_reader :chef_server

      def chef_api
        @chef_api ||= Cheffish.chef_server_api(chef_server)
      end

      #
      # Get the given data
      #
      # @param type [Symbol] The type of thing to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to retrieve
      #
      # @return [Hash,Array] The data.  Will be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def get_data(type, name)
        begin
          if type == :machine
            chef_api.get("nodes/#{name}")
          else
            chef_api.get("data/#{data_bag_name(type)}/#{name}")
          end
        rescue Net::HTTPServerException => e
          if e.response.code == '404'
            nil
          else
            raise
          end
        end
      end

      #
      # Save the given data
      #
      # @param type [Symbol] The type of thing to save (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet ...)
      # @param name [String] The unique identifier of the thing to save
      # @param data [Hash,Array] The data to save.  Must be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def save_data(type, name, data, action_handler)
        _chef_server = self.chef_server
        Chef::Provisioning.inline_resource(action_handler) do
          if type == :machine
            chef_node name do
              chef_server _chef_server
              raw_json data
            end
          else
            chef_data_bag_item name do
              chef_server _chef_server
              data_bag data_bag_name(type)
              raw_json data
            end
          end
        end
      end

      #
      # Delete the given data
      #
      # @param type [Symbol] The type of thing to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to delete
      #
      # @return [Boolean] Whether anything was deleted or not.
      #
      def delete_data(type, name)
        _chef_server = self.chef_server
        Chef::Provisioning.inline_resource(action_handler) do
          if type == :machine
            chef_node name do
              chef_server _chef_server
              action :delete
            end
          else
            chef_data_bag_item name do
              chef_server _chef_server
              data_bag data_bag_name(type)
              action :delete
            end
          end
        end
      end

      def identifier(type, name)
        if type == :machine
          File.join(chef_server[:chef_server_url], "nodes", name)
        else
          File.join(chef_server[:chef_server_url], "data", data_bag_name(type), name)
        end
      end

      private

      def data_bag_name(type)
        case type
        when :machine
          raise "PROGRAMMER ERROR: Machine is stored in nodes, data_bag_name should never have been called on it"
        when :machine_image
          "images"
        when :load_balancer
          "loadbalancers"
        else
          type.to_s
        end
      end
    end
  end
end
