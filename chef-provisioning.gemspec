$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/provisioning/version'

Gem::Specification.new do |s|
  s.name = 'chef-provisioning'
  s.version = Chef::Provisioning::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'LICENSE' ]
  s.summary = 'A library for creating machines and infrastructures idempotently in Chef.'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'jkeiser@chef.io'
  s.homepage = 'http://github.com/chef/chef-provisioning/README.md'

  s.add_dependency 'chef', '>= 11.16.4'
  s.add_dependency 'net-ssh', '~> 2.0'
  s.add_dependency 'net-scp', '~> 1.0'
  s.add_dependency 'net-ssh-gateway', '~> 1.2.0'
  s.add_dependency 'inifile', '~> 2.0'
  s.add_dependency 'cheffish', '~> 1.1'
  s.add_dependency 'winrm', '~> 1.2.0'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'

  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md CHANGELOG.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
