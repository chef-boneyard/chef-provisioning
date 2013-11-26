require 'chef_metal/machine/basic_machine'

module ChefMetal
  class Machine
    class UnixMachine < BasicMachine
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
          provider.converge_by "delete file #{path} on #{node['name']}" do
            transport.execute("rm -f #{path}").error!
          end
        end
      end

      # Return true or false depending on whether file exists
      def file_exists?(path)
        transport.execute("ls -d #{path}").stdout != ''
      end

      def create_dir(provider, path)
        if !file_exists?(path)
          provider.converge_by "create directory #{path} on #{node['name']}" do
            transport.execute("mkdir #{path}").error!
          end
        end
      end

      # Set file attributes { mode, :owner, :group }
      def set_attributes(provider, path, attributes)
        if attributes[:mode] || attributes[:owner] || attributes[:group]
          current_attributes = get_file_attributes(path)
          if attributes[:mode] && current_attributes[:mode] != attributes[:mode]
            provider.converge_by "change mode of #{path} on #{node['name']} from #{current_attributes[:mode].to_i(8)} to #{attributes[:mode].to_i(8)}" do
              transport.execute("chmod #{attributes[:mode].to_i(8)} #{path}").error!
            end
          end
          if attributes[:owner] && current_attributes[:owner] != attributes[:owner]
            provider.converge_by "change group of #{path} on #{node['name']} from #{current_attributes[:owner]} to #{attributes[:owner]}" do
              transport.execute("chown #{attributes[:owner]} #{path}").error!
            end
          end
          if attributes[:group] && current_attributes[:group] != attributes[:group]
            provider.converge_by "change group of #{path} on #{node['name']} from #{current_attributes[:group]} to #{attributes[:group]}" do
              transport.execute("chgrp #{attributes[:group]} #{path}").error!
            end
          end
        end
      end

      # Get file attributes { :mode, :owner, :group }
      def get_attributes(path)
        file_info = transport.execute("ls -ld #{path}").stdout.split(/\s+/)
        if file_info.size <= 1
          raise "#{path} does not exist in set_attributes()"
        end
        result = {
          :mode => 0,
          :owner => file_info[2],
          :group => file_info[3]
        }
        attribute_string = file_info[0]
        0.upto(attribute_string.length-1).each do |i|
          result[:mode] <<= 1
          result[:mode] += (attribute_string[i] == '-' ? 0 : 1)
        end
        result
      end

      def dirname_on_machine(path)
        path.split('/')[0..-2].join('/')
      end
    end
  end
end