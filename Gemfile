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
  gem "ohai"
  gem "chef"
  gem "chefstyle", "~> 0.10.0"
  gem "rake"
  gem "rspec", "~> 3.0"
  gem "simplecov"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
