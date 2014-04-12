include_recipe 'myapp::vagrant'
include_recipe 'myapp::linux'

def chef_repo_path
  "#{ENV['HOME']}/machinetest/repo"
end

def source_path
  "#{ENV['HOME']}/oc/code/opscode"
end

def vagrant_cluster_path
  "#{ENV['HOME']}/machinetest"
end

def chef_server
  the_source_path = source_path

  directory chef_repo_path

  directory "#{chef_repo_path}/cookbooks" do
    action :delete
    recursive true
  end

  execute "berks install" do
    cwd "#{the_source_path}/chef-metal/cookbooks/myapp"
  end

  execute "berks vendor #{chef_repo_path}/cookbooks" do
    cwd "#{the_source_path}/chef-metal/cookbooks/myapp"
  end

  with_chef_local_server :chef_repo_path => chef_repo_path
end

def test_vagrant
  include_recipe 'myapp::vagrant'
  include_recipe 'myapp::linux'

  machine 'everything-vagrant' do
    action [:create, :stop]
    run_list %w(recipe[build-essential])
    TestHelper.upload_latest_gem_files(self, %w(chef-metal-fog chef-metal-vagrant chef-metal chef-metal-docker chef-metal-lxc lxc-extra))
  end
end

def test_vagrant_lxc
  include_recipe 'myapp::vagrant'
  include_recipe 'myapp::linux'

  machine 'everything-vagrant' do
    action [:create, :stop]
    converge true
    run_list %w(recipe[myapp::install_lxc] recipe[myapp::testlxc])
  end
end

def test_vagrant_docker
  include_recipe 'myapp::vagrant'
  include_recipe 'myapp::linux'

  machine 'everything-vagrant' do
    action [:create, :stop]
    converge true
    run_list %w(recipe[docker] recipe[myapp::testdocker])
  end
end

def test_ec2
  include_recipe 'myapp::ec2'

  machine 'everything-ec2' do
    action [:create, :stop]
    run_list %w(recipe[build-essential])
    TestHelper.upload_latest_gem_files(self, %w(chef-metal-fog chef-metal-vagrant chef-metal chef-metal-docker chef-metal-lxc lxc-extra))
  end
end

def test_ec2_docker
  include_recipe 'myapp::ec2'

  machine 'everything-ec2' do
    action [:create, :stop]
    converge true
    run_list %w(recipe[docker] recipe[myapp::testdocker])
  end
end

def delete_vagrant
  include_recipe 'myapp::vagrant'
  include_recipe 'myapp::linux'
  machine 'everything-vagrant' do
    action :delete
  end
end

def delete_ec2
  include_recipe 'myapp::ec2'
  machine 'everything-ec2' do
    action :delete
  end
end

TestHelper.build_latest_gem_files(self, 'chef-metal-fog', 'chef-metal-vagrant', 'chef-metal', 'chef-metal-docker', 'chef-metal-lxc', 'lxc-extra')

chef_server
delete_vagrant
test_vagrant
test_vagrant_docker
#delete_ec2
#test_ec2
#test_ec2_docker


#machine 'everything_digitalocean' do
#  action [:create, :stop]
#end
