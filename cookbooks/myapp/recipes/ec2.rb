include_recipe 'chef-metal'

ec2testdir = File.expand_path('~/ec2test')

directory ec2testdir

with_provisioner ChefMetal::Provisioner::FogProvisioner.new(
  :provider => 'AWS',
  :aws_credentials => '~/.credentials.aws.csv'
)

fog_key_pair 'me' do
  private_key_path "#{ec2testdir}/me"
  public_key_path "#{ec2testdir}/me.pub"
end
