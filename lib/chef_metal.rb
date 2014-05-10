# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_batch'
require 'chef/provider/machine_batch'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'
require 'chef/resource/machine_execute'
require 'chef/provider/machine_execute'
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
      update = Array(update).map { |u| "#{prefix}#{u}"}
      action_handler.performed_action(update)
    end
  end

  # Helpers for driver inflation
  @@registered_driver_classes = {}
  def self.add_registered_driver_class(name, driver)
    @@registered_driver_classes[name] = driver
  end

  def self.driver_config_for_url(driver_url, explicit_config = nil, config = Chef::Config)
    if config[:drivers] && config[:drivers][driver_url]
      driver_config = Cheffish::MergedConfig.new(config[:drivers][driver_url], config)[:driver_config]
    else
      driver_config = config[:drivers][:driver_url]
    end
    driver_config ||= {}
    if explicit_config
      driver_config = Cheffish::MergedConfig.new(explicit_config, driver_config)
    end
    driver_config
  end

  def self.driver_for_url(driver_url, explicit_config = nil, config = Chef::Config)
    cluster_type = driver_url.split(':', 2)[0]
    require "chef_metal/driver_init/#{cluster_type}"
    driver_class = @@registered_driver_classes[cluster_type]
    driver_config = driver_config_for_url(driver_url, explicit_config, config)
    driver_class.from_url(driver_url, driver_config || {})
  end

  def self.connect_to_machine(machine_spec, config = Chef::Config)
    driver = driver_for_url(machine_spec.driver_url, nil, config)
    if driver
      driver.connect_to_machine(machine_spec)
    else
      nil
    end
  end
end
