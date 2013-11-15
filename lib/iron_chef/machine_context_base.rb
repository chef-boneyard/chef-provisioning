module Cheffish
  class MachineContextBase
    def initialize(bootstrapper, name)
      @bootstrapper = bootstrapper
      @name = name
    end

    attr_reader :bootstrapper
    attr_reader :name
    attr_reader :node_json

    # Returns an object that can be used to do remote files, executions, etc.
    # in your recipe.  It can be used in several ways:
    #
    # on_machine = machine_context.resources(self)
    # on_machine.file "/etc/x.txt" do
    #   content 'hi there'
    # end
    #
    # machine_context.resources(self) do
    #   execute "echo hello world"
    #   file "/etc/x.txt" do
    #     content 'hi there'
    #   end
    # end
    def resources(recipe_context)
      raise "resources must be defined in #{self.class}"
    end

    # Gets desired node json (may not be on the server yet), and adds any attributes the machine context
    # wants to have.  Caller is responsible for subsequently saving the node json.
    def filter_node(node_json)
      @node_json = node_json
    end

    # Read a file from the machine.  Returns nil if the machine is down or inaccessible.
    def read_file(path)
      result = execute "sudo cat #{path}"
      result.stdout
    end

    # Put a file on the machine.  Raises an error if it fails.
    def put_file(path, contents)
      raise "put_file must be defined in #{self.class}"
    end

    # Deleta a file on the machine.
    def delete_file(path)
      result = execute "sudo rm -f #{path}"
      result.error!
    end

    # Create a directory on the meachine
    def create_directory(path)
      result = execute "sudo mkdir #{path}"
      result.error!
    end

    # Remove a directory on the machine
    def remove_directory(path)
      result = execute "sudo rmdir #{path}"
      result.error!
    end

    # Tell whether a file or directory exists on the machine
    def file_exists(path)
      result = execute "sudo ls #{path}"
      result.stdout != ''
    end

    # Execute a command inside the machine.  Returns a result with .exitstatus, .stdout and .stderr
    def execute(command)
      raise "execute must be defined on #{self.class}"
    end

    # Converge
    def converge
      execute("sudo chef-client")
    end

    # Disconnect any persistent connections to the machine.
    def disconnect
      raise "disconnect must be defined on #{self.class}"
    end
  end
end
