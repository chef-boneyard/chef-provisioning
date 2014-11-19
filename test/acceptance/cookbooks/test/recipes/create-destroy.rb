machine_name = 'create-destroy'

machine machine_name do
  files '/hello' => { :content => 'world' }
end

machine_execute "test `cat /hello` = 'world'" do
  machine machine_name
end

machine machine_name do
  action :destroy
end

raise 'expected node list to be empty' unless search(:node, "name:#{machine_name}").empty?
