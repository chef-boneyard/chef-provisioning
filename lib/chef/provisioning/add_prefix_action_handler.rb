require 'chef/provisioning/action_handler'

class Chef
module Provisioning
  class AddPrefixActionHandler
    extend Forwardable

    def initialize(action_handler, prefix)
      @action_handler = action_handler
      @prefix = prefix
    end

    attr_reader :action_handler
    attr_reader :prefix
    attr_reader :locally_updated

    def_delegators :@action_handler, :should_perform_actions, :updated!, :open_stream, :host_node

    def report_progress(description)
      @locally_updated = true
      action_handler.report_progress(Array(description).flatten.map { |d| "#{prefix}#{d}" })
    end

    def performed_action(description)
      @locally_updated = true
      action_handler.performed_action(Array(description).flatten.map { |d| "#{prefix}#{d}" })
    end

    def perform_action(description, &block)
      @locally_updated = true
      action_handler.perform_action(Array(description).flatten.map { |d| "#{prefix}#{d}" }, &block)
    end
  end
end
end
