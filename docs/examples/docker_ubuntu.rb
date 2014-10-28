require 'chef_provisioning_docker'

machine 'wario' do
  recipe 'apache'

  machine_options :docker_options => {
    :base_image => {
        :name => 'ubuntu',
        :repository => 'ubuntu',
        :tag => '14.04'
    },

    :command => '/usr/sbin/httpd'
  }

end

