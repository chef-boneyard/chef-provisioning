require 'chef_metal/convergence_strategy'
require 'pathname'
require 'cheffish'

module ChefMetal
  class ConvergenceStrategy
    class NoConverge < ConvergenceStrategy
      def initialize(options)
        super
      end

      def setup_convergence(action_handler, machine)
        machine_spec.save(action_handler)
      end

      def converge(action_handler, machine)
      end

      def cleanup_convergence(action_handler, machine_spec)
        _self = self
        ChefMetal.inline_resource(action_handler) do
          chef_node machine_spec.name do
            chef_server _self.options[:chef_server]
            action :delete
          end
          chef_client machine_spec.name do
            chef_server _self.options[:chef_server]
            action :delete
          end
        end
      end
    end
  end
end
