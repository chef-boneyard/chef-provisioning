require 'cheffish/with_pattern'
require 'chef/mixin/deep_merge'

module ChefMetal
  class ChefRunData
    extend Cheffish::WithPattern
    def initialize(config)
      @config = config
      @drivers = {}
    end

    attr_reader :config
    attr_reader :drivers

    with :driver
    with :machine_options
    with :machine_batch

    def current_driver
      if @current_driver
        @current_driver
      elsif config[:driver]
        driver_for_url(config[:driver])
      end
    end

    def current_machine_options
      if @current_machine_options
        @current_machine_options
      elsif config[:drivers] && current_driver && config[:drivers][current_driver.driver_url]
        MergedConfig.new(config[:drivers][current_driver.driver_url], config)[:machine_options] || {}
      else
        config[:machine_options] || {}
      end
    end

    def add_machine_options(options, &block)
      with_machine_options(Chef::Mixin::DeepMerge.hash_only_merge(current_machine_options, options), &block)
    end

    def driver_for_url(driver_url)
      drivers[driver_url] ||= ChefMetal.driver_for_url(driver_url, nil, config)
    end

    def connect_to_machine(name, chef_server = nil)
      if name.is_a?(MachineSpec)
        machine_spec = name
      else
        machine_spec = ChefMetal::MachineSpec.get(name, chef_server)
      end
      ChefMetal.connect_to_machine(machine_spec, config)
    end
  end
end
