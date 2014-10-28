require 'chef_provisioning/action_handler'

module ChefProvisioning
  class AddPrefixActionHandler
    extend Forwardable

    def initialize(action_handler, prefix)
      @action_handler = action_handler
      @prefix = prefix
    end

    attr_reader :action_handler
    attr_reader :prefix

    def_delegators :@action_handler, :should_perform_actions, :updated!, :open_stream, :host_node

    def report_progress(description)
      action_handler.report_progress(Array(description).flatten.map { |d| "#{prefix}#{d}" })
    end

    def performed_action(description)
      action_handler.performed_action(Array(description).flatten.map { |d| "#{prefix}#{d}" })
    end

    def perform_action(description, &block)
      action_handler.perform_action(Array(description).flatten.map { |d| "#{prefix}#{d}" }, &block)
    end
  end
end
