require 'chef_metal_aws'
with_driver 'aws'

with_data_center 'eu-west-1' do
  aws_auto_scaling_group 'my-awesome-auto-scaling-group' do
    action :delete
  end

  aws_launch_config 'my-sweet-launch-config' do
    action :delete
  end
end
