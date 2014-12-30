require 'chef/provisioning/docker_driver'

machine 'wario' do
  recipe 'apache2'

  machine_options :docker_options => {
    :base_image => {
        :name => 'ubuntu',
        :repository => 'ubuntu',
        :tag => '14.04'
    },

    :command => 'service apache2 start'
  }

end

