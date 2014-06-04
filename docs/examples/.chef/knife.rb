# This file exists mainly to ensure we don't pick up knife.rb from anywhere else
local_mode true
config_dir "#{File.expand_path('..', __FILE__)}/" # Wherefore art config_dir, chef?

# Chef 11.14 binds to "localhost", which interferes with port forwarding on IPv6 machines for some reason
begin
  chef_zero.host '127.0.0.1'
rescue
end
