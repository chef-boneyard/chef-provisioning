require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc "run specs"
RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
end

desc "run core gem specs and generated driver specs"
task :all => ["driver:spec", :spec]

FAKE_DIR = "chef-provisioning-fake"

namespace :driver do
  desc "generate a '#{FAKE_DIR}' driver"
  task :generate do
    sh "./bin/generate_driver fake"
  end

  desc "run specs for #{FAKE_DIR}"
  task :spec do
    sh "cd #{FAKE_DIR} && bundle exec rspec"
  end

  desc "generate a #{FAKE_DIR} driver and run its specs"
  task :verify => [:generate, :spec]

  task :clean do
    sh "rm -rf #{FAKE_DIR}"
  end

  desc "generate a fresh #{FAKE_DIR} driver, run its specs, and delete it"
  task :cycle do
    Rake::Task['driver:clean'].invoke
    Rake::Task['driver:clean'].reenable
    Rake::Task['driver:verify'].invoke
    Rake::Task['driver:clean'].invoke
  end
end

require "chef/provisioning/version"

begin
  require 'github_changelog_generator/task'

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.future_release = Chef::Provisioning::VERSION
    config.enhancement_labels = "enhancement,Enhancement,New Feature".split(',')
    config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(',')
    config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog".split(',')
  end
rescue LoadError
  # It's OK if the github_changelog_generator isn't there, that happens when we're testing older chef versions
end
