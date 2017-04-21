source "https://rubygems.org"
gemspec

#gem 'mixlib-install', path: '../mixlib-install'
#gem 'net-ssh', :path => '../net-ssh'
#gem 'chef', :path => '../chef'
#gem 'ohai', :path => '../ohai'
#gem 'cheffish', :path => '../cheffish' # :git => 'https://github.com/jkeiser/cheffish.git'
#gem 'chef-provisioning-vagrant', :path => '../chef-provisioning-vagrant'
#gem 'chef-provisioning-fog', :path => '../chef-provisioning-fog'
#gem 'chef-provisioning-aws', :path => '../chef-provisioning-aws'
#gem 'chef-zero', :path => '../chef-zero'
group :development do
  # TODO we depend on the master branch until 13 is released and used in the ChefDK
  gem "ohai", git: "https://github.com/chef/ohai", branch: "master"
  gem "chef", git: "https://github.com/chef/chef", branch: "master"
end
