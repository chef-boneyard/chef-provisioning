require 'chef/mixin/deep_merge'
require 'cheffish/with_pattern'
require 'cheffish/merged_config'
require 'chef_metal/chef_machine_spec'

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

    def auto_batch_machines
      if !@auto_batch_machines.nil?
        @auto_batch_machines
      else
        config[:auto_batch_machines]
      end
    end

    def auto_batch_machines=(value)
      @auto_batch_machines = value
    end

    def current_driver
      @current_driver || config[:driver]
    end

    def current_machine_options
      if @current_machine_options
        @current_machine_options
      else
        driver_config_for(current_driver)[:machine_options] || {}
      end
    end

    def add_machine_options(options, &block)
      with_machine_options(Chef::Mixin::DeepMerge.hash_only_merge(current_machine_options, options), &block)
    end

    def driver_for(driver)
      driver.is_a?(String) ? driver_for_url(driver) : driver
    end

    def driver_config_for(driver)
      ChefMetal.config_for_url(driver_for(driver).driver_url, config)
    end

    def driver_for_url(driver_url)
      drivers[driver_url] ||= begin
        driver = ChefMetal.driver_for_url(driver_url, config)
        # Check the canonicalized driver_url from the driver
        if driver.driver_url != driver_url
          drivers[driver.driver_url] ||= driver
        else
          driver
        end
      end
    end

    def connect_to_machine(name, chef_server = nil)
      if name.is_a?(MachineSpec)
        machine_spec = name
      else
        machine_spec = ChefMetal::ChefMachineSpec.get(name, chef_server)
      end
      ChefMetal.connect_to_machine(machine_spec, config)
    end

    def keys
      result = (config.keys || {}).dup
      Array(config.key_path) do |key_path|
        Dir.entries(key_path).each do |key|
          if File.extname(key) == '.pem'
            result[File.basename(key)[0..-5]] ||= key
          end
        end
      end
      result
    end
  end
end
