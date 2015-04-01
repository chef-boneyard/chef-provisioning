# machine 'mario' do
#   action :destroy
# end
# machine 'mario' do
# end

# Create the hosts
machine_batch 'docker hosts' do
  1.upto(2) do |i|
    machine "dockerhost#{i}" do
      recipe "docker"
      attribute %w(docker host), 'tcp://localhost:5555'
    end
  end
end

require 'chef/provisioning/docker_driver'

at_converge_time "create docker containers" do

  with_docker_host 'dockerhost1' do

    machine "web1" do
    end
    machine "web2" do
    end


  end

  with_docker_host "dockerhost2" do

    machine "web3" do
    end

  end
end

# NEXT: build the docker containers.

# Create a web image
# with_driver 'on-host:dockerhost1:docker' do
#   machine_image "base" do
#     recipe 'apt'
#   end
# end

# machine_batch do
#
#   # Create 4 web containers
#   with_driver 'host_proxy:dockerhost1:docker' do
#     machine "web1" do
#     end
#     machine "web2" do
#     end
#   end
#
#   with_driver 'host_proxy:dockerhost1:docker' do
#     machine "web3" do
#     end
#     machine "web4" do
#     end
#   end
# end
