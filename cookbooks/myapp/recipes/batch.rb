require 'chef_metal'

with_machine_batch 'the_new_batch', :action => [ :destroy, :converge ]
1.upto(5) do |i|
  machine "batch#{i}"
end
