require 'chef_metal/action_handler'

module ChefMetal
  class AddPrefixActionHandler
    extend Forwardable

    def initialize(action_handler, prefix)
      @action_handler = action_handler
      @prefix = prefix
    end

    attr_reader :action_handler
    attr_reader :prefix

    def_delegators :@action_handler, :recipe_context, :updated!, :debug_name, :open_stream
    # TODO REMOVE THIS WITH EXTREME PREJUDICE AT THE EARLIEST OPPORTUNITY
    def_delegators :@action_handler, :new_resource

    def perform_action(description, &block)
      action_handler.perform_action("#{prefix}#{description}", &block)
    end
  end
end
