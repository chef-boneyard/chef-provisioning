include_recipe 'iron-chef'

vagrant_cluster "#{ENV['HOME']}/machinetest"

vagrant_box 'precise64'

#machine 'mama_mia' do
#  recipe 'blah'
#  tag 'woo'
#end

machine 'mario'