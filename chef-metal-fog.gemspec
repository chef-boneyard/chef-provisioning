$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef_metal_fog/version'

Gem::Specification.new do |s|
  s.name = 'chef-metal-fog'
  s.version = ChefMetalFog::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ['README.md', 'LICENSE' ]
  s.summary = 'Driver for creating Fog instances in Chef Metal.'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'jkeiser@getchef.com'
  s.homepage = 'https://github.com/opscode/chef-metal-fog'

  s.add_dependency 'chef'
  s.add_dependency 'cheffish', '>= 0.4'
#  s.add_dependency 'chef-metal', '~> 0.5' # We are installed by default with chef-metal, so we don't circular dep back
  s.add_dependency 'fog'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'

  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
