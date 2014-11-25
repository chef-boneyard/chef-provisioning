machine_list = ['create-1', 'create-2']

machine_batch do
  machines machine_list
end

machine_batch do
  machine_list.each { |m|
    machine m do
      recipe 'build-essential'
    end
  }
  action :converge_only
end
