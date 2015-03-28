chef_gem 'chef-provisioning' do
  compile_time true
end
chef_gem 'chef-provisioning-aws' do
  compile_time true
end
chef_gem 'chef-provisioning-azure' do
  compile_time true
end
chef_gem 'chef-provisioning-docker' do
  compile_time true
end
require 'chef/provisioning/aws_driver'
