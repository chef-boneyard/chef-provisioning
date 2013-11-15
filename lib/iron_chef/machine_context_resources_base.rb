module Cheffish
  class MachineContextResourcesBase
    def initialize(machine_context, recipe_context)
      @machine_context = machine_context
      @recipe_context = recipe_context
    end

    attr_reader :machine_context
    attr_reader :recipe_context

    def converge_resource_name
      "chef_converge[#{machine_context.name}]"
    end

    # Create the raw machine, power it up such that it can be connected to.
    # When this resource succeeds, a connection can be made to the machine so that read_file and chef_client_setup
    # can be run against it.
    #
    # Attributes include standard resource attributes, plus:
    # before PROC - calls proc with (resource) just before resource executes
    def raw_machine(&block)
      raise "raw_machine must be defined on #{self.class}"
    end

    # Create a directory on the machine.  Should be done in resources added to recipe_context.
    #
    # Attributes include standard resource attributes, plus:
    # action :create, :delete
    def directory(path, &block)
      resource = recipe_context.ruby_block "create directory '#{path}' on machine #{machine_context.name}"
      action = :create
      each_resource_attribute_pair(block) do |name, *args, &block|
        if name == :action
          action = args[0]
        else
          resource.send(name, *args, &block)
        end
      end
      if action == :delete
        resource.block { machine_context.remove_directory(path) }
        resource.only_if { machine_context.file_exists(path) }
      else
        resource.block { machine_context.create_directory(path) }
        resource.only_if { !machine_context.file_exists(path) }
      end

      resource
    end

    # Get a file onto the machine.  Should be done in resources added to recipe_context.
    #
    # Attributes include standard resource attributes, plus:
    # action :create, :delete
    # content "TEXT" - content to put in file
    def file(path, &block)
      resource = recipe_context.ruby_block "update file '#{path}' on machine #{machine_context.name}"
      content = nil
      action = :create
      each_resource_attribute_pair(block) do |name, *args, &block|
        if name == :content
          content = args[0]
        elsif name == :action
          action = args[0]
        else
          resource.send(name, *args, &block)
        end
      end
      if action == :delete
        resource.block { machine_context.delete_file(path) }
        resource.only_if { machine_context.read_file(path) != nil }
      else
        resource.block { machine_context.put_file(path, content) }
        resource.only_if { machine_context.read_file(path) != content }
      end

      resource
    end

    # Run a command on a machine.  Should be done in resources added to recipe_context.
    #
    # Attributes include standard resource attributes, plus:
    # command "COMMAND" - command to run
    # cwd "/path/to/run/in" - path to run command in
    # source "/path/to/source/file.txt" - file to read source data from
    def execute(name, &block)
      resource = recipe_context.ruby_block "run '#{name}' on machine #{machine_context.name}"
      # Intercept "command" and "cwd"
      command = name
      cwd = nil
      each_resource_attribute_pair(block) do |name, *args, &block|
        if name == :command
          command = args[0]
        elsif name == :cwd
          cwd = args[0]
        else
          resource.send(name, *args, &block)
        end
      end
      resource.block { machine_context.execute(command, cwd) }
      resource
    end

    # Disconnect any outstanding connections.  Should be done in resources added to recipe_context.
    #
    # Does not take any attributes.
    def disconnect(&block)
      the_machine_context = machine_context
      recipe_context.ruby_block "disconnect from machine #{machine_context.name}" do
        block { XXX }
        # Execute the stuff we want in only_if so it doesn't print green text
        only_if { the_machine_context.disconnect; false }
      end
    end

    # Setup chef-client (but do not run it).  Should be done in resources added to recipe_context.
    #
    # Attributes include standard resource attributes, plus:
    # client_name "NAME" - name of client to authenticate as
    # client_key "KEY" - private key for client
    # client_options { 'name' => 'value', ... } - client options
    # before PROC - calls proc with (resource) just before resource executes
    def chef_client_setup(&block)
      resource = recipe_context.chef_client_setup(machine_context.name, &block)
      resource.machine_context machine_context
      resource
    end

    # Converge the machine.  Should be done in resources added to recipe_context.
    #
    # Attributes include standard resource attributes, plus:
    def chef_converge(&block)
      resource = recipe_context.chef_converge(machine_context.name, &block)
      resource.machine_context machine_context
      resource
    end

    protected

    def each_resource_attribute_pair(block, &yield_to)
      if block
        MethodMissingYielder.new(lambda { |*args, &block| yield_to.call(*args, &block) }).instance_eval(&block)
      end
    end

    class MethodMissingYielder
      def initialize(block)
        @block = block
      end

      def method_missing(name, *args, &block_arg)
        @block.call(name, *args, &block_arg)
      end
    end
  end
end
