include_recipe 'chef-metal'

openstack_testdir = File.expand_path('~/openstack_test')

directory openstack_testdir

with_fog_openstack_provisioner

fog_key_pair 'me' do
  private_key_path "#{openstack_testdir}/me"
  public_key_path "#{openstack_testdir}/me.pub"
end
