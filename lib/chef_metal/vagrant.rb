require 'chef_metal'
require 'chef/resource/vagrant_cluster'
require 'chef/provider/vagrant_cluster'
require 'chef/resource/vagrant_box'
require 'chef/provider/vagrant_box'
require 'chef_metal/provisioner/vagrant_provisioner'

module ChefMetal
  def self.with_vagrant_cluster(cluster_path, &block)
    with_provisioner(ChefMetal::Provisioner::VagrantProvisioner.new(cluster_path), &block)
  end

  def self.with_vagrant_box(box_name, provisioner_options = nil, &block)
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
end
