require 'chef_provisioning'

machine_image 'foo'

machine 'quiddle' do
  from_image 'foo'
end

machine 'baz' do
  from_image 'foo'
end
