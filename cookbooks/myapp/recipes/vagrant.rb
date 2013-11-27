include_recipe 'chef-metal'

# Set up a vagrant cluster (place for vms) in ~/machinetest
vagrant_cluster "#{ENV['HOME']}/machinetest" do
end
