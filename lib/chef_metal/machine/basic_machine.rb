require 'chef_metal/machine'

module ChefMetal
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
          transport.execute(command).error!
        end
      end

      def execute_always(command)
        transport.execute(command)
      end

      def read_file(path)
        transport.read_file(path)
      end

      def download_file(provider, path, local_path)
        if files_different?(path, local_path)
          provider.converge_by "download file #{path} on #{node['name']} to #{local_path}" do
            transport.download_file(path, local_path)
          end
        end
      end

      def write_file(provider, path, content, options = {})
        if files_different?(path, nil, content)
          if options[:ensure_dir]
            create_dir(provider, dirname_on_machine(path))
          end
          provider.converge_by "write file #{path} on #{node['name']}" do
            transport.write_file(path, content)
          end
        end
      end

      def upload_file(provider, local_path, path, options = {})
        if files_different?(path, local_path)
          if options[:ensure_dir]
            create_dir(provider, dirname_on_machine(path))
          end
          provider.converge_by "upload file #{local_path} to #{path} on #{node['name']}" do
            transport.upload_file(local_path, path)
          end
        end
      end

      def forward_remote_port_to_local(remote_port, local_port)
        transport.forward_remote_port_to_local(remote_port, local_port)
      end

      def disconnect
        transport.disconnect
      end
    end
  end
end