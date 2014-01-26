machine 'mario' do
  #recipe 'mydb'
  tag 'mydb_master'
end

machine_file '/etc/blah.conf' do
  machine 'mario'
  content 'hi'
end

machine 'mario' do
  action :delete
end

num_webservers = 100

1.upto(num_webservers) do |i|
  machine "luigi#{i}" do
    #recipe 'apache'
    #recipe 'mywebapp'
    action [ :create, :delete ]
#    action [ :create, :stop ]
  end
end
