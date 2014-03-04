include_recipe 'chef-metal'

chef_gem 'fog'

require 'chef_metal/fog'

openstack_testdir = File.expand_path('~/openstack_test')

directory openstack_testdir

with_fog_provisioner :provider => 'OpenStack',
    :openstack_api_key => ENV['OS_PASSWORD'],
    :openstack_username => ENV['OS_USERNAME'],
    :openstack_auth_url => ENV['OS_AUTH_URL'],
    :openstack_tenant => ENV['OS_TENANT_NAME'],
    :base_bootstrap_options => {
      :flavor_ref => 2,
      :name => 'chef_test',
      :image_ref => '920c7654-50ec-4a76-98d1-288c554a7ec3',
      :floating_ip => '75.55.110.189'
    }

fog_key_pair 'me' do
  private_key_path "#{openstack_testdir}/me"
  public_key_path "#{openstack_testdir}/me.pub"
end

with_provisioner_options :flavor_ref => 2

machine 'chef_test' do
  recipe 'apt'
end
