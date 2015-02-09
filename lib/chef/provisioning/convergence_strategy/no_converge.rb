require 'chef/provisioning/convergence_strategy'
require 'pathname'
require 'cheffish'

class Chef
module Provisioning
  class ConvergenceStrategy
    class NoConverge < ConvergenceStrategy
      def chef_server
        @chef_server ||= convergence_options[:chef_server] || Cheffish.default_chef_server(config)
      end

      def setup_convergence(action_handler, machine)
      end

      def converge(action_handler, machine)
      end

      def cleanup_convergence(action_handler, machine_spec)
        _self = self
        Chef::Provisioning.inline_resource(action_handler) do
          chef_node machine_spec.name do
            chef_server _self.chef_server
            action :delete
          end
          chef_client machine_spec.name do
            chef_server _self.chef_server
            action :delete
          end
        end
      end
    end
  end
end
end
