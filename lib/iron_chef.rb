# Include recipe basics so require 'iron_chef' will load everything
require 'iron_chef/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/vagrant_cluster'
require 'chef/provider/vagrant_cluster'
require 'chef/resource/vagrant_box'
require 'chef/provider/vagrant_box'
require 'iron_chef/inline_resource'

module IronChef
  def self.with_provisioner(provisioner)
    old_provisioner = IronChef.enclosing_provisioner
    IronChef.enclosing_provisioner = provisioner
    if block_given?
      begin
        yield
      ensure
        IronChef.enclosing_provisioner = old_provisioner
      end
    end
  end

  def self.with_vagrant_cluster(cluster_path, &block)
    require 'iron_chef/vagrant/vagrant_provisioner'

    old_vagrant_cluster = IronChef.enclosing_vagrant_cluster
    IronChef.enclosing_vagrant_cluster = cluster_path
    new_provisioner = IronChef.enclosing_vagrant_options ?
                      IronChef::Vagrant::VagrantProvisioner.new(cluster_path, IronChef.enclosing_vagrant_options) :
                      IronChef.enclosing_provisioner
    if block
      begin
        with_provisioner(new_provisioner, &block)
      ensure
        IronChef.enclosing_vagrant_cluster = old_vagrant_cluster
      end
    else
      with_provisioner(new_provisioner)
    end
  end

  def self.with_vagrant_box(box_name, vagrant_options = {}, &block)
    require 'chef/resource/vagrant_box'

    if box_name.is_a?(Chef::Resource::VagrantBox)
      vagrant_options = vagrant_options || box_name.vagrant_options
      vagrant_options['vm.box'] = box_name.name
      vagrant_options['vm.box_url'] = box_name.url
    else
      vagrant_options['vm.box'] = box_name
    end

    with_vagrant_options(vagrant_options, &block)
  end

  def self.with_vagrant_options(vagrant_options, &block)
    require 'iron_chef/vagrant/vagrant_provisioner'

    old_vagrant_options = IronChef.enclosing_vagrant_options
    IronChef.enclosing_vagrant_options = vagrant_options
    new_provisioner = IronChef.enclosing_vagrant_cluster ?
                      IronChef::Vagrant::VagrantProvisioner.new(IronChef.enclosing_vagrant_cluster, vagrant_options) :
                      IronChef.enclosing_provisioner
    if block
      begin
        with_provisioner(new_provisioner, &block)
      ensure
        IronChef.enclosing_vagrant_options = old_vagrant_options
      end
    else
      with_provisioner(new_provisioner)
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

  @@enclosing_vagrant_cluster = nil
  def self.enclosing_vagrant_cluster
    @@enclosing_vagrant_cluster
  end
  def self.enclosing_vagrant_cluster=(vagrant_cluster)
    @@enclosing_vagrant_cluster = vagrant_cluster
  end

  @@enclosing_vagrant_options = nil
  def self.enclosing_vagrant_options
    @@enclosing_vagrant_options
  end
  def self.enclosing_vagrant_options=(vagrant_options)
    @@enclosing_vagrant_options = vagrant_options
  end
end
