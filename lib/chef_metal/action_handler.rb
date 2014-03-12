# This is included in the metal provisioners to proxy from generic requests needed
# to specific provider actions
module ProviderActionHandler
  def recipe_context
    self.run_context
  end

  def update!
    self.new_resource.updated_by_last_action(true)
  end

  def perform_action(description, &block)
    self.converge_by(description, &block)
  end

  def debug_name
    self.cookbook_name
  end
end

# This is used by the Test Kitchen metal driver for the parts of the provider interface
# that needs to be supported (though isn't necessarily for the things Kitchen needs the
# provisioner to do when called directly)
class KitchenActionHandler
  def initialize(name)
    @debug_name = "name"
  end

  def recipe_context
    node = Chef::Node.new
    node.name 'nothing'
    node.automatic[:platform] = 'kitchen_metal'
    node.automatic[:platform_version] = 'kitchen_metal'
    Chef::Config.local_mode = true
    Chef::RunContext.new(node, {},
      Chef::EventDispatch::Dispatcher.new(Chef::Formatters::Doc.new(STDOUT,STDERR)))
  end

  def update!
    @updated = true
  end

  def perform_action(description, &block)
    puts description
    block.call
  end

  def debug_name
    @debug_name
  end
end
