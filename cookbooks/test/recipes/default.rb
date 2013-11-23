include_recipe 'iron-chef'

vagrant_cluster "#{ENV['HOME']}/machinetest"

if false
vagrant_box 'precise64'

machine 'luigi' do
  recipe 'blah'
  tag 'woo'
end

machine 'mario'

end

vagrant_box 'opscode-windows-6.1' do
  provisioner_options({
    'vagrant_options' => {
      'vm.guest' => :windows,
      'windows.halt_timeout' => 25,
      'winrm.username' => 'vagrant',
      'winrm.password' => 'vagrant'
    },
    'vagrant_config' => "config.vm.network :forwarded_port, guest: 5985, host: 5985"
  })
end

# small_webapp.rb
machine 'link' do
  recipe 'apache'
end
