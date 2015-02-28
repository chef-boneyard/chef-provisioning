require 'chef/provisioning/managed_entry_store'
require 'cheffish'

class Chef
  module Provisioning
    class ChefManagedEntryStore < ManagedEntryStore
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
      # @param resource_type [Symbol] The type of thing to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to retrieve
      #
      # @return [Hash,Array] The data, or `nil` if the data does not exist.  Will be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def get_data(resource_type, name)
        begin
          if resource_type == :machine
            chef_api.get("nodes/#{name}")
          else
            chef_api.get("data/#{resource_type}/#{name}")
          end
        rescue Net::HTTPServerException => e
          if e.response.code == '404'
            backcompat_type = ChefManagedEntryStore.type_names_for_backcompat[resource_type]
            if backcompat_type && backcompat_type != resource_type
              get_data(backcompat_type, name)
            else
              nil
            end
          else
            raise
          end
        end
      end

      #
      # Save the given data
      #
      # @param resource_type [Symbol] The type of thing to save (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet ...)
      # @param name [String] The unique identifier of the thing to save
      # @param data [Hash,Array] The data to save.  Must be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def save_data(resource_type, name, data, action_handler)
        _chef_server = self.chef_server
        Chef::Provisioning.inline_resource(action_handler) do
          if resource_type == :machine
            chef_node name do
              chef_server _chef_server
              raw_json data
            end
          else
            chef_data_bag resource_type.to_s do
              chef_server _chef_server
            end
            chef_data_bag_item name do
              chef_server _chef_server
              data_bag resource_type.to_s
              raw_data data
            end
          end
        end

        backcompat_type = ChefManagedEntryStore.type_names_for_backcompat[resource_type]
        if backcompat_type && backcompat_type != resource_type
          delete_data(backcompat_type, name, action_handler)
        end
      end

      #
      # Delete the given data
      #
      # @param resource_type [Symbol] The type of thing to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to delete
      #
      # @return [Boolean] Whether anything was deleted or not.
      #
      def delete_data(resource_type, name, action_handler)
        _chef_server = self.chef_server
        Chef::Provisioning.inline_resource(action_handler) do
          if resource_type == :machine
            chef_node name do
              chef_server _chef_server
              action :delete
            end
          else
            chef_data_bag_item name do
              chef_server _chef_server
              data_bag resource_type.to_s
              action :delete
            end
          end
        end

        backcompat_type = ChefManagedEntryStore.type_names_for_backcompat[resource_type]
        if backcompat_type && backcompat_type != resource_type
          delete_data(backcompat_type, name, action_handler)
        end
      end

      def identifier(resource_type, name)
        if resource_type == :machine
          File.join(chef_server[:chef_server_url], "nodes", name)
        else
          File.join(chef_server[:chef_server_url], "data", resource_type.to_s, name)
        end
      end

      #
      # A list of the name that we used to use to store a given type before we
      # standardized on "just use the resource name so we don't create collisions."
      # Will be used to look up the old data.
      #
      def self.type_names_for_backcompat
        @@type_names_for_backcompat ||= {}
      end
    end
  end
end
