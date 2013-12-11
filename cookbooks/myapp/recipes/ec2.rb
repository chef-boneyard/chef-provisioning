include_recipe 'chef-metal'

require 'chef_metal/aws_credentials'
ChefMetal::AWSCredentials.load(File.expand_path('~/.credentials.aws.csv'))

with_provisioner ChefMetal::Provisioner::FogProvisioner.new(
  :provider => 'AWS',
#  :region=>'eu-west-1',
  :aws_access_key_id => ChefMetal::AWSCredentials['metal_test'][:access_key_id],
  :aws_secret_access_key => ChefMetal::AWSCredentials['metal_test'][:secret_access_key]
)

ec2testdir = "#{ENV['HOME']}/ec2test"
directory ec2testdir

private_key "#{ec2testdir}/me"

public_key "#{ec2testdir}/me.pub" do
  source_key_path "#{ec2testdir}/me"
end

fog_key_pair 'me' do
  source_key_path "#{ec2testdir}/me"
end

with_provisioner_options({
  :bootstrap_options => {
    :private_key_path => "#{ec2testdir}/me",
    :public_key_path => "#{ec2testdir}/me.pub"
  }
})
