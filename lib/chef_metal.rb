# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/vagrant_cluster'
require 'chef/provider/vagrant_cluster'
require 'chef/resource/vagrant_box'
require 'chef/provider/vagrant_box'

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

  def self.with_vagrant_cluster(cluster_path, &block)
    require 'chef_metal/provisioner/vagrant_provisioner'

    with_provisioner(ChefMetal::Provisioner::VagrantProvisioner.new(cluster_path), &block)
  end

  def self.with_vagrant_box(box_name, provisioner_options = nil, &block)
    require 'chef/resource/vagrant_box'

    if box_name.is_a?(Chef::Resource::VagrantBox)
      provisioner_options ||= box_name.provisioner_options || {}
      provisioner_options['vagrant_options'] ||= {}
      provisioner_options['vagrant_options']['vm.box'] = box_name.name
      provisioner_options['vagrant_options']['vm.box_url'] = box_name.url if box_name.url
    else
      provisioner_options ||= {}
      provisioner_options['vagrant_options'] ||= {}
      provisioner_options['vagrant_options']['vm.box'] = box_name
    end

    with_provisioner_options(provisioner_options, &block)
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
end
