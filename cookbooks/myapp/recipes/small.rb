machine 'mario' do
  #recipe 'mydb'
  tag 'mydb_master'
  action [:delete, :create]
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
    #recipe 'apache'
    #recipe 'mywebapp'
    action [ :create, :stop ]
  end
end
