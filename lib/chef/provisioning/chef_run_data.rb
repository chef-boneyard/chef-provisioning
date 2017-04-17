require 'chef/mixin/deep_merge'
require 'cheffish/merged_config'

class Chef
module Provisioning
  class ChefRunData

    def initialize(config)
      @config = config
      @drivers = {}
    end

    attr_reader :config
    attr_reader :drivers
    attr_reader :current_driver
    attr_accessor :current_machine_options
    attr_accessor :current_load_balancer_options
    attr_accessor :current_image_options

    def with_machine_options(value)
      old_value = self.current_machine_options
      self.current_machine_options = value
      if block_given?
        begin
          yield
        ensure
          self.current_machine_options = old_value
        end
      end
    end

    def with_image_options(value)
      old_value = self.current_image_options
      self.current_image_options = value
      if block_given?
        begin
          yield
        ensure
          self.current_image_options = old_value
        end
      end
    end

    def with_driver(driver, options = nil, &block)
      if drivers[driver] && options
        raise "Driver #{driver} has already been created, options #{options} would be ignored!"
      end
      old_driver, old_options = @current_driver, @current_driver_options
      @current_driver, @current_driver_options = driver, options
      if block_given?
        begin
          yield
        ensure
          @current_driver, @current_driver_options = old_driver, old_options
        end
      end
    end

    def current_driver
      @current_driver || config[:driver]
    end

    def current_machine_options
      if @current_machine_options
        @current_machine_options
      else
        {}
      end
    end

    def current_image_options
      if @current_image_options
        @current_image_options
      else
        {}
      end
    end

    def add_machine_options(options, &block)
      with_machine_options(Chef::Mixin::DeepMerge.hash_only_merge(current_machine_options, options), &block)
    end

    def driver_for(driver)
      driver.is_a?(String) ? driver_for_url(driver) : driver
    end

    def connect_to_machine(name, chef_server = nil)
      if name.is_a?(ManagedEntry)
        machine_spec = name
      else
        machine_spec = Provisioning.chef_managed_entry_store(chef_server).get(:machine, name)
      end
      Chef::Provisioning.connect_to_machine(machine_spec, config)
    end

    private

    def driver_for_url(driver_url)
      drivers[driver_url] ||= begin
        if driver_url == @current_driver && @current_driver_options
          # Use the driver options if available
          merged_config = Cheffish::MergedConfig.new({ :driver_options => @current_driver_options }, config.to_hash)
          driver = Chef::Provisioning.driver_for_url(driver_url, merged_config)
        else
          driver = Chef::Provisioning.driver_for_url(driver_url, config)
        end
        # Check the canonicalized driver_url from the driver
        if driver.driver_url != driver_url
          if drivers[driver.driver_url] && @current_driver_options
            raise "Canonical driver #{driver.driver_url} for #{driver_url} has already been created!  Current options #{@current_driver_options} would be ignored."
          end
          drivers[driver.driver_url] ||= driver
        else
          driver
        end
      end
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
end
