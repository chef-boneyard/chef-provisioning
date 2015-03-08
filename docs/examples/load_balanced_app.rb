require 'chef/provisioning'
require 'chef/provisioning/driver_init/aws'

with_driver 'aws::us-west-2'

aws_vpc 'blah' do
  cidr_block '10.0.0.0/16'
end

machine 'mario' do
  tag 'itsa_me'
  converge true
end
