require 'iron_chef/machine/basic_machine'

module IronChef
  class Machine
    class WindowsMachine < BasicMachine
      def initialize(node, transport, convergence_strategy)
        super
      end

      # Options include:
      #
      # command_prefix - prefix to put in front of any command, e.g. sudo
      attr_reader :options

      # Delete file
      def delete_file(provider, path)
        if file_exists?(path)
          provider.converge_by "delete file #{escape(path)} on #{node['name']}" do
            transport.execute("Remove-Item #{escape(path)}").error!
          end
        end
      end

      # Return true or false depending on whether file exists
      def file_exists?(path)
        parse_boolean(transport.execute("Test-Path #{escape(path)}").stdout)
      end

      def create_dir(provider, path)
        if !file_exists?(path)
          provider.converge_by "create directory #{path} on #{node['name']}" do
            transport.execute("New-Item #{escape(path)} -Type directory")
          end
        end
      end

      # Set file attributes { :owner, :group, :rights }
#      def set_attributes(provider, path, attributes)
#      end

      # Get file attributes { :owner, :group, :rights }
#      def get_attributes(path)
#      end

      def dirname_on_machine(path)
        path.split(/[\\\/]/)[0..-2].join('\\')
      end

      def escape(string)
        transport.escape(string)
      end

      def parse_boolean(string)
        if string =~ /^\s*true\s*$/mi
          true
        else
          false
        end
      end
    end
  end
end