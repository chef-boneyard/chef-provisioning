require 'chef_metal/transport'
require 'lxc/extra'
require 'chef/mixin/shell_out'

module ChefMetal
  class Transport
    class LXCTransport < Transport

      class LXCExecuteResult < Struct.new(:stdout, :stderr, :exitstatus)
        def error!
          raise "Error: code #{exitstatus}.\nSTDOUT:#{stdout}\nSTDERR:#{stderr}" if exitstatus != 0
        end
      end

      attr_reader :name, :options, :lxc_path

      include Chef::Mixin::ShellOut

      def initialize(name, lxc_path, options={})
        @options = options
        @name = name
        @lxc_path = lxc_path
      end

      def ct
        @container ||= LXC::Container.new(name, lxc_path)
      end

      def rootfs
        ct.config_item('lxc.rootfs')
      end

      def ct_path(path)
        File.join(rootfs, path)
      end

      def execute(command)
        Chef::Log.info("Executing #{command} on #{name}")
        res = ct.execute do
                begin
                  out = shell_out(command)
                  LXCExecuteResult.new(out.stdout,out.stderr, out.exitstatus)
                rescue Exception => e
                  LXCExecuteResult.new('', e.message, -1)
                end
              end
        res
      end

      def forward_remote_port_to_local(remote_port, local_port)
        warn 'Port forwarding is not implemented in lxc transport'
        warn "You can do this on host using:"
        warn "   'iptables -t nat -A PREROUTING -p tcp --dport #{remote_port} -j DNAT --to #{ct.ip_addresses.first}:#{local_port}'"
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
