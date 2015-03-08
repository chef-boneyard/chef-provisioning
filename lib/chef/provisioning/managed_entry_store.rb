require 'chef/provisioning/load_balancer_spec'
require 'chef/provisioning/machine_spec'
require 'chef/provisioning/machine_image_spec'
require 'chef/provisioning/managed_entry'

class Chef
  module Provisioning
    class ManagedEntryStore
      def initialize(chef_run_data)
        @chef_run_data = chef_run_data
      end

      #
      # Get the given data
      #
      # @param resource_type [Symbol] The type of thing to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to retrieve
      #
      # @return [Hash,Array] The data.  Will be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def get_data(resource_type, name)
        raise NotImplementedError, :get_data
      end

      #
      # Save the given data
      #
      # @param resource_type [Symbol] The type of thing to save (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet ...)
      # @param name [String] The unique identifier of the thing to save
      # @param data [Hash,Array] The data to save.  Must be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def save_data(resource_type, name, data, action_handler)
        raise NotImplementedError, :save_data
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
        raise NotImplementedError, :delete_data
      end

      #
      # Get a globally unique identifier for this resource.
      #
      # @param resource_type [Symbol] The type of spec to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to retrieve
      #
      # @return [String] The identifier.
      #
      # @example ChefManagedEntry does this:
      #   chef_managed_entry_store.identifier(:machine, 'mario') # => https://my.chef.server/organizations/org/nodes/mario
      #
      def identifier(resource_type, name)
        raise NotImplementedError, :identifier
      end

      #
      # Get a spec.
      #
      # @param resource_type [Symbol] The type of spec to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to retrieve
      #
      # @return [ManagedEntry] The entry, or `nil` if the data does not exist.
      #
      def get(resource_type, name)
        data = get_data(resource_type, name)
        if data
          new_entry(resource_type, name, data)
        end
      end

      #
      # Get a spec, or create a new one, depending on whether an entry exists.
      #
      # @param resource_type [Symbol] The type of spec to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to retrieve
      #
      # @return [ManagedEntry] The entry.
      #
      def get_or_new(resource_type, name)
        data = get_data(resource_type, name)
        new_entry(resource_type, name, data)
      end

      #
      # Get a spec, erroring out if the data does not exist.
      #
      # @param resource_type [Symbol] The type of spec to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to retrieve
      #
      # @return [ManagedEntry] The entry.
      #
      def get!(resource_type, name)
        result = get(resource_type, name)
        if !result
          raise "#{identifier(resource_type, name)} not found!"
        end
        result
      end

      #
      # Delete the given spec.
      #
      # @param resource_type [Symbol] The type of spec to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to delete
      #
      # @return [Boolean] Whether anything was deleted or not.
      #
      def delete(resource_type, name, action_handler)
        delete_data(resource_type, name, action_handler)
      end

      #
      # Create a new managed entry of the given type.
      #
      def new_entry(resource_type, name, data=nil)
        case resource_type
        when :machine
          MachineSpec.new(self, resource_type, name, data)
        when :machine_image
          MachineImageSpec.new(self, resource_type, name, data)
        when :load_balancer
          LoadBalancerSpec.new(self, resource_type, name, data)
        else
          ManagedEntry.new(self, resource_type, name, data)
        end
      end
    end
  end
end
