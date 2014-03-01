require 'chef_metal/transport'
require 'lxc/extra'
require 'chef/mixin/shell_out'
require 'ostruct'

module ChefMetal
  class Transport
    class LXCTransport < Transport

      attr_reader :name
      attr_reader :options

      include Chef::Mixin::ShellOut

      def initialize(name, options={})
        @options = options
        @name = name
      end

      def ct
        @container ||= LXC::Container.new(name)
      end

      def rootfs
        ct.config_item('lxc.rootfs')
      end

      def ct_path(path)
        File.join(rootfs, path)
      end

      def execute(command)
        Chef::Log.info("Executing #{command} on #{name}")
        res = nil
        begin 
          res = ct.execute do
                  out = shell_out(command)
                  OpenStruct.new(:stdout=>out.stdout, :stderr=> out.stderr, :exitstatus => out.exitstatus)
                end
        rescue Exception => e
          res = OpenStruct.new(:stdout=>'', :stderr=>e.message, :exitstatus => -1)
        end
        res
      end

      def forward_remote_port_to_local(remote_port, local_port)
      end

      def read_file(path)
        if File.exists?(ct_path(path))
          File.read(ct_path(path))
        end
      end

      def download_file(path, local_path)
        Chef::Log.debug("Copying file #{path} from #{name} to local #{local_path}")
        FileUtils.cp_r(ct_path(path), local_path)
      end

      def write_file(path, content)
        File.open(ct_path(path), 'w') do |f|
          f.write(content)
        end
      end

      def upload_file(local_path, path)
        FileUtils.cp_r(local_path, ct_path(path))
      end

      def disconnect
      end

      def available?
        begin
          execute('pwd')
          true
        rescue Exception =>e
          false
        end
      end
    end
  end
end
