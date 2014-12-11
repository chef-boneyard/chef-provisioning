require 'support/spec_support'

describe 'machine idempotence' do
  extend SpecSupport

  when_the_repository 'is empty' do

    it 'runs' do
      run_recipe do
        require 'chef/provisioning/vagrant_driver'

        with_chef_local_server :chef_repo_path => Chef::Config.chef_repo_path

        with_driver 'vagrant'

        vagrant_box 'precise64' do
          url 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/vmware/opscode_ubuntu-12.04_chef-provisionerless.box'
        end

        machine 'blah'
      end
    end

  end
end
