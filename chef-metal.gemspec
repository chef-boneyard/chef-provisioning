$:.unshift(File.dirname(__FILE__) + '/lib')
Gem::Specification.new do |s|
  s.name = 'chef-metal'
  s.version = '0.15'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A library for creating machines and infrastructures idempotently in Chef.'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'jkeiser@getchef.com'
  s.homepage = 'http://github.com/opscode/chef-metal'

  s.add_dependency 'chef-provisioning'
end
