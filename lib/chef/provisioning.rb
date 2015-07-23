# Include recipe basics so require 'chef/provisioning' will load everything
require 'chef/provisioning/recipe_dsl'
require 'chef/server_api'
require 'cheffish/basic_chef_client'
require 'cheffish/merged_config'
require 'chef/provisioning/chef_managed_entry_store'

class Chef
module Provisioning
  def self.inline_resource(action_handler, &block)
    events = ActionHandlerForward.new(action_handler)
    Cheffish::BasicChefClient.converge_block(nil, events, &block)
  end

  class ActionHandlerForward < Chef::EventDispatch::Base
    def initialize(action_handler)
      @action_handler = action_handler
    end

    attr_reader :action_handler

    def resource_update_applied(resource, action, update)
      prefix = action_handler.should_perform_actions ? "" : "Would "
      update = Array(update).flatten.map { |u| "#{prefix}#{u}"}
      action_handler.performed_action(update)
    end
  end

  # Helpers for driver inflation
  @@registered_driver_classes = {}
  def self.register_driver_class(name, driver)
    @@registered_driver_classes[name] = driver
  end

  def self.default_driver(config = Cheffish.profiled_config)
    driver_for_url(config[:driver], config)
  end

  def self.driver_for_url(driver_url, config = Cheffish.profiled_config, allow_different_config = false)
    #
    # Create and cache the driver
    #
    #
    # Figure out the driver class
    #
    scheme = driver_url.split(':', 2)[0]
    begin
      require "chef/provisioning/driver_init/#{scheme}"
    rescue LoadError
      begin
        require "chef_metal/driver_init/#{scheme}"
      rescue LoadError
        # try the doomed require again so the stack trace shows the first LoadError and not the second (which
        # would throw a confusing "chef_metal" into the error output of what is now chef-provisioning). one
        # could also experiment with saving the first LoadError and re-raising it.
        require "chef/provisioning/driver_init/#{scheme}"
      end
    end
    driver_class = @@registered_driver_classes[scheme]
    if !driver_class
      raise "chef/provisioning/driver_init/#{scheme} did not register a driver class for #{scheme.inspect}!  Perhaps you have the case (uppercase or lowercase) wrong?"
    end

    #
    # Merge in any driver-specific config
    #
    if config[:drivers] && config[:drivers][driver_url]
      config = Cheffish::MergedConfig.new(config[:drivers][driver_url], config)
    end

    #
    # Canonicalize the URL
    #
    canonicalized_url, canonicalized_config = driver_class.canonicalize_url(driver_url, config)
    config = canonicalized_config if canonicalized_config

    #
    # Merge in config from the canonicalized URL if it is different
    #
    if canonicalized_url != driver_url
      if config[:drivers] && config[:drivers][canonicalized_url]
        config = Cheffish::MergedConfig.new(config[:drivers][canonicalized_url], config)
      end
    end

    driver_class.from_url(canonicalized_url, config)
  end

  def self.connect_to_machine(machine_spec, config = Cheffish.profiled_config)
    chef_server = Cheffish.default_chef_server(config)
    if machine_spec.is_a?(String)
      machine_spec = chef_managed_entry_store(chef_server).get(:machine, machine_spec)
    end
    driver = driver_for_url(machine_spec.driver_url, config)
    if driver
      machine_options = { :convergence_options => { :chef_server => chef_server } }
      machine_options = Cheffish::MergedConfig.new(config[:machine_options], machine_options) if config[:machine_options]
      driver.connect_to_machine(machine_spec, machine_options)
    else
      nil
    end
  end

  def self.chef_managed_entry_store(chef_server = Cheffish.default_chef_server)
    Provisioning::ChefManagedEntryStore.new(chef_server)
  end
end
end

ChefMetal = Chef::Provisioning
