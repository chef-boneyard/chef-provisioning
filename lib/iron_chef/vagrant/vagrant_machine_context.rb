require 'chef/mixin/shell_out'

module Cheffish
  class VagrantMachineContext < MachineContextBase
    include Chef::Mixin::ShellOut

    def initialize(bootstrapper, name)
      super
    end

    def configuration_path
      "/etc/chef"
    end

    def resources(recipe_context)
      result = VagrantMachineContextResources.new(self, recipe_context)
      result.instance_eval(lambda { yield self }) if block_given?
      result
    end

    def read_file(path)
      result = execute "sudo cp #{path} /vagrant/tmpfile"
      result.error!
      IO.read(File.join(bootstrapper.base_path, 'tmpfile'))
    end

    # Put a file on the machine.  Raises an error if it fails.
    def put_file(path, contents)
      File.open(File.join(bootstrapper.base_path, 'tmpfile'), 'w') do |file|
        file.write(contents)
      end
      result = execute "sudo cp /vagrant/tmpfile #{path}"
      result.error!
    end

    def execute(command, cwd=nil)
      # TODO is this enough escaping?
      command = command.gsub("'", "\\'")
      if cwd
        vagrant("ssh #{name} -c 'cd #{cwd} && #{command}'")
      else
        vagrant("ssh #{name} -c '#{command}'")
      end
    end

    def disconnect
      # Vagrant does not connect, so it doesn't disconnect either
    end

    # Used by VagrantMachineContext to get the string used to configure vagrant
    def vm_config_string(variable, line_prefix)
      hostname = name.gsub(/[^A-Za-z0-9\-]/, '-')

      result = ''
      bootstrapper.vm_config.merge(:hostname => hostname).each_pair do |key, value|
        result += "#{line_prefix}#{variable}.#{key} = #{value.inspect}\n"
      end
      result
    end

    def box_file_path
      File.join(bootstrapper.base_path, "#{name}.vm")
    end

    def box_file_exists
      File.exist?(box_file_path)
    end

    def vagrant(command)
      shell_out("vagrant #{command}", :cwd => bootstrapper.base_path)
    end
  end
end
