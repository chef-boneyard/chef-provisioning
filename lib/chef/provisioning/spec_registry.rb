require 'chef/provisioning/machine_spec'
require 'chef/provisioning/machine_image_spec'
require 'chef/provisioning/load_balancer_spec'
require 'chef/provisioning/generic_spec'

class Chef
  module Provisioning
    class SpecRegistry
      #
      # Get the given data
      #
      # @param type [Symbol] The type of thing to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to retrieve
      #
      # @return [Hash,Array] The data.  Will be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def get_data(type, name)
        raise NotImplementedError, :get_data
      end

      #
      # Save the given data
      #
      # @param type [Symbol] The type of thing to save (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet ...)
      # @param name [String] The unique identifier of the thing to save
      # @param data [Hash,Array] The data to save.  Must be JSON- and YAML-compatible (Hash, Array, String, Integer, Boolean, Nil)
      #
      def save_data(type, name, data, action_handler)
        raise NotImplementedError, :save_data
      end

      #
      # Delete the given data
      #
      # @param type [Symbol] The type of thing to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the thing to delete
      #
      # @return [Boolean] Whether anything was deleted or not.
      #
      def delete_data(type, name, action_handler)
        raise NotImplementedError, :delete_data
      end

      #
      # Get a spec
      #
      # @param type [Symbol] The type of spec to retrieve (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to retrieve
      #
      # @return [GenericSpec] The data.
      #
      def get(type, name)
        data = get_data(type, name)
        if data
          new_spec(type, name, data)
        end
      end

      def get!(type, name)
        result = get(type, name)
        if !result
          raise "#{identifier(type, name)} not found!"
        end
        result
      end

      def identifier(type, name)
        raise NotImplementedError, :identifier
      end


      #
      # Create an empty spec of the given type
      #
      def new_spec(type, name, data={})
        case type
        when :machine
          MachineSpec.new(self, type, name, data)
        when :image
          MachineImageSpec.new(self, type, name, data)
        when :load_balancer
          LoadBalancerSpec.new(self, type, name, data)
        else
          GenericSpec.new(self, type, name, data)
        end
      end

      #
      # Delete the given spec.
      #
      # @param type [Symbol] The type of spec to delete (:machine, :machine_image, :load_balancer, :aws_vpc, :aws_subnet, ...)
      # @param name [String] The unique identifier of the spec to delete
      #
      # @return [Boolean] Whether anything was deleted or not.
      #
      def delete(type, name, action_handler)
        delete_data(type, name, action_handler)
      end
    end
  end
end
