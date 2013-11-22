require 'chef/mixin/shell_out'

module IronChef
  class Transport
    class VagrantSSH
      include Chef::Mixin::ShellOut

      def initialize(base_path, name)
        @base_path = base_path
        @name = name
      end

      attr_reader :base_path
      attr_reader :name

      def execute(command)
        # TODO is this enough escaping?
        command = command.gsub("'", "\\'")
        shell_out("vagrant ssh #{name} -c '#{command}'", :cwd => base_path)
      end

      def read_file(path)
        result = execute "sudo cp #{path} /vagrant/tmpfile"
        if result.exitstatus == 0
          IO.read(File.join(base_path, 'tmpfile'))
        else
          nil
        end
      end

      def put_file(path, contents)
        File.open(File.join(base_path, 'tmpfile'), 'w') do |file|
          file.write(contents)
        end
        result = execute "sudo cp /vagrant/tmpfile #{path}"
        result.error!
      end

      def disconnect
      end
    end
  end
end