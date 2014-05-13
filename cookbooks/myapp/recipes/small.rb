require 'chef_metal'

file '/tmp/blah.txt' do
  content 'woo'
end

with_machine_batch 'blah', :action => :nothing

machine 'mario' do
  #recipe 'mydb'
  tag 'mydb_master'
  action [:delete, :converge]
end

machine_file '/etc/blah.conf' do
  machine 'mario'
  content 'hi'
end

machine 'mario' do
  action :stop
end

num_webservers = 1

1.upto(num_webservers) do |i|
  machine "luigi#{i}" do
    file '/etc/woo.txt' => '/tmp/blah.txt'
    file '/etc/woo2.txt', '/tmp/blah.txt'
    file '/etc/woo3.txt', :local_path => '/tmp/blah.txt'
    file '/etc/woo4.txt', :content => 'WOOOOOOO'
    #recipe 'apache'
    #recipe 'mywebapp'
    action [ :converge, :stop ]
  end
end
