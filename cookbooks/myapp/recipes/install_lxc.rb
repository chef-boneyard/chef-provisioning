# Ubuntu 12, not Ubuntu 14
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 12
  execute 'apt-get update' do
    action :nothing
  end.run_action(:run)

  package 'python-software-properties' do
    action :nothing
  end.run_action(:install)

  package 'make' do
    action :nothing
  end.run_action(:install)
end

execute 'add-apt-repository ppa:ubuntu-lxc/stable' do
  action :nothing
end.run_action(:run)

execute 'apt-get update' do
  action :nothing
end.run_action(:run)

# Needed for Ubuntu 14, not Ubuntu 12
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 14
  package 'ruby1.9.1-dev' do
    action :nothing
  end.run_action(:upgrade)
end

package 'lxc' do
  action :nothing
end.run_action(:upgrade)

package 'lxc-dev' do
  action :nothing
end.run_action(:upgrade)

package 'lxc-templates' do
  action :nothing
end.run_action(:upgrade)

