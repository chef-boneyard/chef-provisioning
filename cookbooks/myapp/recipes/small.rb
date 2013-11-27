machine 'mario' do
  recipe 'mydb'
  tag 'mydb_master'
end

num_webservers = 1

1.upto(num_webservers) do |i|
  machine "luigi#{i}" do
    recipe 'apache'
    recipe 'mywebapp'
  end
end
