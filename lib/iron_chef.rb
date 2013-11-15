# Include recipe basics so require 'iron_chef' will load everything
require 'iron_chef/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/chef_converge'
require 'chef/provider/chef_converge'
require 'chef/resource/chef_client_setup'
require 'chef/provider/chef_client_setup'
require 'chef/resource/vagrant_cluster'
require 'chef/provider/vagrant_cluster'
require 'chef/resource/vagrant_vm'
require 'chef/provider/vagrant_vm'

module IronChef
  @@enclosing_bootstrapper = nil
  def self.enclosing_bootstrapper
    @@enclosing_bootstrapper
  end
  def self.enclosing_bootstrapper=(bootstrapper)
    @@enclosing_bootstrapper = bootstrapper
  end
end
