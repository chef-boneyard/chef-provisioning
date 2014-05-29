require 'chef_metal'

machine_batch do
  action [ :destroy, :converge ]
  1.upto(5) do |i|
    machine "batch#{i}"
  end
end
