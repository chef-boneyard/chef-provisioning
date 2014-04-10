file '/tmp/blah.txt' do
  content 'woo'
end

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
    file '/etc/woo.txt' => '/tmp/blah.txt'
    file '/etc/woo2.txt', '/tmp/blah.txt'
    file '/etc/woo3.txt', :local_path => '/tmp/blah.txt'
    file '/etc/woo4.txt', :content => 'WOOOOOOO'
    #recipe 'apache'
    #recipe 'mywebapp'
    action [ :create, :stop ]
  end
end
