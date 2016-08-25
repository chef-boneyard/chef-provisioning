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

  s.required_ruby_version = ">= 2.2.2"

  s.add_dependency 'net-ssh', '>= 2.9', '< 4.0'
  s.add_dependency 'net-scp', '~> 1.0'
  s.add_dependency 'net-ssh-gateway', '~> 1.2.0'
  s.add_dependency 'inifile', '>= 2.0.2'
  s.add_dependency 'cheffish', '~> 4.0'
  s.add_dependency 'winrm', '~> 1.3'
  s.add_dependency "mixlib-install",  "~> 1.0"

  s.add_development_dependency 'chef', '~> 12.1', "!= 12.4.0"  # 12.4.0 is incompatible.
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'github_changelog_generator'

  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Gemfile Rakefile LICENSE README.md CHANGELOG.md) + Dir.glob("*.gemspec") +
      Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
