require 'chef/provisioning'

machine_batch do
  machines search(:node, '*:*').map { |n| n.name }
  action :destroy
end
