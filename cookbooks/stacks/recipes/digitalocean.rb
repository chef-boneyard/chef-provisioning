require 'chef_metal'

api_key = ENV['DIGITALOCEAN_API_KEY']
client_id = ENV['DIGITALOCEAN_CLIENT_ID']
ec2testdir = File.expand_path('~/ec2test')


directory ec2testdir

with_fog_provisioner :provider => 'DigitalOcean',
  :digitalocean_api_key => api_key,
  :digitalocean_client_id => client_id

fog_key_pair 'me' do
  private_key_path "#{ec2testdir}/me"
  public_key_path "#{ec2testdir}/me.pub"
end
