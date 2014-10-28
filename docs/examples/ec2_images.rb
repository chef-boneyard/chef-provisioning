require 'chef/provisioning'

machine_image 'foo'

machine 'quiddle' do
  from_image 'foo'
end

machine 'baz' do
  from_image 'foo'
end
