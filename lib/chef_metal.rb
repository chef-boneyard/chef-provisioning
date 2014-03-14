# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'

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

  def self.inline_resource(provider, &block)
    InlineResource.new(provider).instance_eval(&block)
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

  @@registered_provisioners = {}
  def self.add_registered_provisioner(name, provisioner)
    @@registered_provisioners[name] = provisioner
  end

  def self.registered_provisioners(name)
    @@registered_provisioners[name]
  end
end
