# Include recipe basics so require 'iron_chef' will load everything
require 'iron_chef/recipe_dsl'
require 'chef/resources/machine'
require 'chef/resources/chef_converge'
require 'chef/resources/chef_client_setup'
require 'chef/providers/machine'
require 'chef/providers/chef_converge'
require 'chef/providers/chef_client_setup'

module IronChef
  @@enclosing_bootstrapper = nil
  def self.enclosing_bootstrapper
    @@enclosing_bootstrapper
  end
  def self.enclosing_bootstrapper=(bootstrapper)
    @@enclosing_bootstrapper = bootstrapper
  end
end
