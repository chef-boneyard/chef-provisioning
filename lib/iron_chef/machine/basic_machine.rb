require 'iron_chef/machine'

module IronChef
  class Machine
    class BasicMachine < Machine
      def initialize(node, transport, convergence_strategy)
        super(node)
        @transport = transport
        @convergence_strategy = convergence_strategy
      end

      attr_reader :transport
      attr_reader :convergence_strategy

      # Sets up everything necessary for convergence to happen on the machine.
      # The node MUST be saved as part of this procedure.  Other than that,
      # nothing is guaranteed except that converge() will work when this is done.
      def setup_convergence(provider, machine_resource)
        convergence_strategy.setup_convergence(provider, self, machine_resource)
      end

      def converge(provider)
        convergence_strategy.converge(provider, self)
      end

      def execute(provider, command)
        provider.converge_by "run '#{command}' on #{node['name']}" do
          transport.execute(command)
        end
      end

      def execute_always(command)
        transport.execute(command)
      end

      def read_file(path)
        transport.read_file(path)
      end

      def write_file(provider, path, content)
        if transport.read_file(path) != content
          provider.converge_by "write file #{path} on #{node['name']}" do
            transport.write_file(path, content)
          end
        end
      end

      def disconnect
        transport.disconnect
      end
    end
  end
end