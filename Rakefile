require 'bundler'
require 'bundler/gem_tasks'

task :spec do
  require File.expand_path('spec/run')
end

FAKE_DIR = "chef-provisioning-fake"

desc "generate a '#{FAKE_DIR}' driver"
task :generate do
  sh "./bin/generate_driver fake"
end

desc "run specs for #{FAKE_DIR}"
task :run_specs do
  sh "cd #{FAKE_DIR} && bundle exec rspec"
end

desc "generate a #{FAKE_DIR} driver and run its specs"
task :verify do
  Rake::Task['generate'].invoke
  Rake::Task['run_specs'].invoke
end

task :clean do
  sh "rm -rf #{FAKE_DIR}"
end

desc "generate a fresh #{FAKE_DIR} driver, run its specs, and delete it"
task :cycle do
  Rake::Task['clean'].invoke
  Rake::Task['verify'].invoke
  Rake::Task['clean'].invoke
end
