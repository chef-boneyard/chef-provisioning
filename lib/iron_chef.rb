# Include recipe basics so require 'iron_chef' will load everything
require 'iron_chef/recipe_dsl'
require 'chef/resource/machine'
require 'chef/resource/chef_converge'
require 'chef/resource/chef_client_setup'
require 'chef/provider/machine'
require 'chef/provider/chef_converge'
require 'chef/provider/chef_client_setup'

module IronChef
  @@enclosing_bootstrapper = nil
  def self.enclosing_bootstrapper
    @@enclosing_bootstrapper
  end
  def self.enclosing_bootstrapper=(bootstrapper)
    @@enclosing_bootstrapper = bootstrapper
  end
end
