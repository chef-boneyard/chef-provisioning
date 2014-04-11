# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'
require 'chef/resource/machine_execute'
require 'chef/provider/machine_execute'

require 'chef_metal/inline_resource'

module ChefMetal
  def self.with_provisioner(provisioner)
    old_provisioner = ChefMetal.enclosing_provisioner
    ChefMetal.enclosing_provisioner = provisioner
    if block_given?
      begin
        yield
      ensure
        ChefMetal.enclosing_provisioner = old_provisioner
      end
    end
  end

  def self.with_provisioner_options(provisioner_options)
    old_provisioner_options = ChefMetal.enclosing_provisioner_options
    ChefMetal.enclosing_provisioner_options = provisioner_options
    if block_given?
      begin
        yield
      ensure
        ChefMetal.enclosing_provisioner_options = old_provisioner_options
      end
    end
  end

  def self.inline_resource(action_handler, &block)
    InlineResource.new(action_handler).instance_eval(&block)
  end

  @@enclosing_provisioner = nil
  def self.enclosing_provisioner
    @@enclosing_provisioner
  end
  def self.enclosing_provisioner=(provisioner)
    @@enclosing_provisioner = provisioner
  end

  @@enclosing_provisioner_options = nil
  def self.enclosing_provisioner_options
    @@enclosing_provisioner_options
  end

  def self.enclosing_provisioner_options=(provisioner_options)
    @@enclosing_provisioner_options = provisioner_options
  end

  @@registered_provisioner_classes = {}
  def self.add_registered_provisioner_class(name, provisioner)
    @@registered_provisioner_classes[name] = provisioner
  end

  def self.provisioner_for_node(node)
    provisioner_url = node['normal']['provisioner_output']['provisioner_url']
    cluster_type = provisioner_url.split(':', 2)[0]
    require "chef_metal/provisioner_init/#{cluster_type}_init"
    provisioner_class = @@registered_provisioner_classes[cluster_type]
    provisioner_class.inflate(node)
  end

  def self.connect_to_machine(name)
    rest = Chef::ServerAPI.new()
    node = rest.get("/nodes/#{name}")
    provisioner_output = node['normal']['provisioner_output']
    if !provisioner_output
      raise "Node #{name} was not provisioned with Metal."
    end
    provisioner = provisioner_for_node(node)
    machine = provisioner.connect_to_machine(node)
    [ machine, provisioner ]
  end
end
