require 'chef_metal/convergence_strategy'
require 'pathname'
require 'cheffish'

module ChefMetal
  class ConvergenceStrategy
    class NoConverge < ConvergenceStrategy
      attr_reader :client_rb_path
      attr_reader :client_pem_path

      def setup_convergence(action_handler, machine, machine_resource)
        # Save the node
        ChefMetal.inline_resource(action_handler) do
          # TODO strip automatic attributes first so we don't race with "current state"
          chef_node machine.node['name'] do
            chef_server machine_resource.chef_server
            raw_json machine.node
          end
        end
      end

      def converge(action_handler, machine)
      end

      def cleanup_convergence(action_handler, node)
        ChefMetal.inline_resource(action_handler) do
          chef_node node['name'] do
            action :delete
          end
        end
      end
    end
  end
end
