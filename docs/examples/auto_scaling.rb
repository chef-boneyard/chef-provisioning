require 'chef_metal_aws'
with_driver 'aws'

with_data_center 'eu-west-1' do
  aws_launch_config 'my-sweet-launch-config' do
    image 'ami-f0b11187'
    instance_type 't1.micro'
  end

  aws_auto_scaling_group 'my-awesome-auto-scaling-group' do
    desired_capacity 3
    min_size 1
    max_size 5
    launch_config 'my-sweet-launch-config'
  end
end
