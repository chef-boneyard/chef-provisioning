require 'chef/provisioning/docker_driver'

machine_image 'web_server' do
  recipe 'apache2'

  machine_options :docker_options => {
      :base_image => {
          :name => 'ubuntu',
          :repository => 'ubuntu',
          :tag => '14.04'
      }
  }
end

machine 'web00' do
  from_image 'web_server'

  machine_options :docker_options => {
      :command => '/usr/sbin/httpd'
  }
end
