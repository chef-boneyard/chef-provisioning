#
# First create a provisioners group so the ACLs are all correct
#
chef_group 'provisioners' do
end
# To be able to recreate the provisioners group
chef_acl 'groups' do
  rights :create, groups: 'provisioners'
end
# To be able to add others to the provisioners group
chef_acl 'groups/provisioners' do
  rights [ :read, :update ], groups: 'provisioners'
end
# To be able to create and delete machines
chef_acl 'nodes' do
  rights :all, groups: 'provisioners'
end
chef_acl 'clients' do
  rights :all, groups: 'provisioners'
end

# To be able to create and delete load balancers and images
chef_acl 'data' do
  rights [ :read, :create ], groups: 'provisioners'
  recursive false
end
%w(images load_balancer).each do |data_bag_name|
  chef_data_bag data_bag_name do
  end
  chef_acl "data/#{data_bag_name}" do
    rights :all, groups: 'provisioners'
  end
end


#
# Now let's make a provisioning machine
#
machine 'provisioning-machine' do
  recipe 'my_infrastructure'
end
chef_group 'provisioners' do
  clients 'provisioning-machine'
end
