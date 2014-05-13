require 'chef_metal'
search(:node, 'name:*') do |node|
  machine node.name do
    action :delete
  end
end
