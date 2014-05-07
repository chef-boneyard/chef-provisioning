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

  @@drivers_by_url = {}
  def self.driver_for_url(driver_url)
    @@drivers_by_url[driver_url] ||= begin
      cluster_type = driver_url.split(':', 2)[0]
      require "chef_metal/driver_init/#{cluster_type}"
      driver_class = @@registered_driver_classes[cluster_type]
      driver_class.from_url(driver_url)
    end
  end
end
