vagrant_box 'opscode-windows-6.1' do
  provisioner_options({
    'vagrant_options' => {
      'vm.guest' => :windows,
      'windows.halt_timeout' => 25,
      'winrm.username' => 'vagrant',
      'winrm.password' => 'vagrant'
    },
    'vagrant_config' => "config.vm.network :forwarded_port, guest: 5985, host: 5985",
    'up_timeout' => 30*60
  })
end
