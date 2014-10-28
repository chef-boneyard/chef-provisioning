require 'chef/provisioning/machine'

class Chef
module Provisioning
  class Machine
    class BasicMachine < Machine
      def initialize(machine_spec, transport, convergence_strategy)
        super(machine_spec)
        @transport = transport
        @convergence_strategy = convergence_strategy
      end

      attr_reader :transport
      attr_reader :convergence_strategy

      def setup_convergence(action_handler)
        convergence_strategy.setup_convergence(action_handler, self)
      end

      def converge(action_handler)
        convergence_strategy.converge(action_handler, self)
      end

      def cleanup_convergence(action_handler)
        convergence_strategy.cleanup_convergence(action_handler, machine_spec)
      end

      def execute(action_handler, command, options = {})
        action_handler.perform_action "run '#{command}' on #{machine_spec.name}" do
          result = transport.execute(command, options)
          result.error!
          result
        end
      end

      def execute_always(command, options = {})
        transport.execute(command, options)
      end

      def read_file(path)
        transport.read_file(path)
      end

      def download_file(action_handler, path, local_path)
        if files_different?(path, local_path)
          action_handler.perform_action "download file #{path} on #{machine_spec.name} to #{local_path}" do
            transport.download_file(path, local_path)
          end
        end
      end

      def write_file(action_handler, path, content, options = {})
        if files_different?(path, nil, content)
          if options[:ensure_dir]
            create_dir(action_handler, dirname_on_machine(path))
          end
          action_handler.perform_action "write file #{path} on #{machine_spec.name}" do
            transport.write_file(path, content)
          end
        end
      end

      def upload_file(action_handler, local_path, path, options = {})
        if files_different?(path, local_path)
          if options[:ensure_dir]
            create_dir(action_handler, dirname_on_machine(path))
          end
          action_handler.perform_action "upload file #{local_path} to #{path} on #{machine_spec.name}" do
            transport.upload_file(local_path, path)
          end
        end
      end

      def make_url_available_to_remote(local_url)
        transport.make_url_available_to_remote(local_url)
      end

      def disconnect
        transport.disconnect
      end
    end
  end
end
end
