include_recipe 'iron-chef'

vagrant_cluster "#{ENV['HOME']}/machinetest" do
  vagrant_config :box => 'precise64'
end

#machine 'mama_mia' do
#  recipe 'blah'
#  tag 'woo'
#end

machine 'mama_mia' do
  action :delete
end

machine 'mario' do
  action :delete
end

machine 'mario'