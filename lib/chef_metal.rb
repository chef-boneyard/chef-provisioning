# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/server_api'
require 'cheffish/basic_chef_client'
require 'cheffish/merged_config'

module ChefMetal
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

  def self.config_for_url(driver_url, config = Chef::Config)
    if config && config[:drivers] && config[:drivers][driver_url]
      config = Cheffish::MergedConfig.new(config[:drivers][driver_url], config)
    end
    config || {}
  end

  def self.driver_for_url(driver_url, config = Chef::Config)
    cluster_type = driver_url.split(':', 2)[0]
    require "chef_metal/driver_init/#{cluster_type}"
    driver_class = @@registered_driver_classes[cluster_type]
    config = config_for_url(driver_url, config)
    driver_class.from_url(driver_url, config || {})
  end

  def self.connect_to_machine(machine_spec, config = Chef::Config)
    driver = driver_for_url(machine_spec.driver_url, config)
    if driver
      machine_options = { :convergence_options => { :chef_server => Cheffish.default_chef_server(config) } }
      machine_options = Cheffish::MergedConfig.new(config[:machine_options], machine_options) if config[:machine_options]
      driver.connect_to_machine(machine_spec, machine_options)
    else
      nil
    end
  end
end
