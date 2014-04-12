# Use a Linux image
vagrant_box 'precise64' do
  url 'http://files.vagrantup.com/precise64.box'
  provisioner_options 'vagrant_config' => <<EOM
    config.vm.synced_folder (ENV['SRC_DIR'] || "#{ENV['HOME']}/oc/code/opscode"), "/mnt/host_src"
EOM
end
