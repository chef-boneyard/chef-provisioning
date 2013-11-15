include_recipe 'iron-chef'

require 'iron_chef/vagrant/vagrant_bootstrapper'

with_bootstrapper IronChef::Vagrant::VagrantBootstrapper.new("#{ENV['HOME']}/machinetest", :box => 'precise64')

machine 'mama_mia' do
  recipe 'blah'
  tag 'woo'
end
