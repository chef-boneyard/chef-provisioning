$:.unshift(File.dirname(__FILE__) + '/lib')
require 'iron_chef/version'

Gem::Specification.new do |s|
  s.name = 'iron-chef'
  s.version = IronChef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ['README.md', 'LICENSE' ]
  s.summary = 'A library for creating machines and infrastructures idempotently in Chef.'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'jkeiser@opscode.com'
  s.homepage = 'http://wiki.opscode.com/display/chef'

  s.add_dependency 'chef'
  s.add_dependency 'cheffish'

  s.add_development_dependency 'rspec'
  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
