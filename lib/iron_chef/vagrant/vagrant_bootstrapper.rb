module Cheffish
  class VagrantBootstrapper < BootstrapperBase
    def initialize(base_path, vm_config={})
      @base_path = base_path
      @vm_config = vm_config
    end

    attr_reader :base_path
    attr_reader :vm_config

    def machine_context(name)
      VagrantMachineContext.new(self, name)
    end

    # Idempotently creates the vagrantfile, inside your Chef recipe, with pretty
    # green text and why-run support.
    def vagrantfile(recipe_context)
      the_base_path = base_path
      recipe_context.directory the_base_path
      recipe_context.file File.join(the_base_path, 'Vagrantfile') do
        content <<EOM
Dir.glob('#{File.join(the_base_path, '*.vm')}') do |vm_file|
  eval(IO.read(vm_file), nil, vm_file)
end
EOM
      end
    end
  end
end