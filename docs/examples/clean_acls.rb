# Remove clients from the admins group
chef_group 'admins' do
  remove_groups 'clients'
end

valid_nodes = search(:node, '*:*').map { |node| node.name }

search(:client, '*:*').each do |c|
  if valid_nodes.include?(c.name)
    # Check whether the user exists
    begin
      api = Cheffish.chef_server_api
      api.get("#{api.root_url}/users/#{c.name}").inspect
    rescue Net::HTTPServerException => e
      if e.response.code == '404'
        puts "Response #{e.response.code} for #{c.name}"
        # If the user does NOT exist, we can just add the client to the acl
        chef_acl "nodes/#{c.name}" do
          rights [ :read, :update ], clients: [ c.name ]
        end
        next
      end
    end

    # We will only get here if the user DOES exist. We are going to have a
    # conflict between the user and client. Create a group for it, add
    # the user for that group, and add the group to the acl. Bleagh.
    chef_group "client_#{c.name}" do
      clients c.name
    end
    chef_acl "nodes/#{c.name}" do
      rights [ :read, :update ], groups: "client_#{c.name}"
    end
  end
end
