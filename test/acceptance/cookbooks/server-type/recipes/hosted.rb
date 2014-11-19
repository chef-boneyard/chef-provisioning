require 'chef_metal'


# this will be override via config or cli when written to a databag (maybe?) idk yet
#node.set['chef-server-type']['hosted']['validation-key'] = '/path/to/chef-qa-validator.pem'

# attributes
with_chef_server "https://api.opscode.com/organizations/#{node['chef-server-type']['hosted']['org-name']}",
  :client_name => node['chef-server-type']['hosted']['validation-client-name'],
  :signing_key_filename => node['chef-server-type']['hosted']['validation-key']
