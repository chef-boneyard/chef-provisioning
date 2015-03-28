# Create the hosts
machine_batch do
  machine "dockerhost1" do
    recipe "docker"
  end
  machine "dockerhost2" do
    recipe "docker"
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
