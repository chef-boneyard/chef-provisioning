require 'chef_metal/convergence_strategy'
require 'pathname'
require 'cheffish'

module ChefMetal
  class ConvergenceStrategy
    class NoConverge < ConvergenceStrategy
      attr_reader :client_rb_path
      attr_reader :client_pem_path

      def setup_convergence(action_handler, machine, machine_resource)
        machine_spec.save(action_handler)
      end

      def converge(action_handler, machine)
      end

      def cleanup_convergence(action_handler, machine_spec)
        ChefMetal.inline_resource(action_handler) do
          chef_node machine_spec.name do
            action :delete
          end
          chef_client machine_spec.name do
            action :delete
          end
        end
      end
    end
  end
end
