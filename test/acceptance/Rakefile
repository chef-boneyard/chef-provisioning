Dir.glob('lib/tasks/*.rake').each { |r| import r }

desc "Print help message"
task :help do
  puts "Run 'rake bundle' and 'rake berks' to setup your project"
  puts "Run 'rspec spec -t driver_family:cloud' to run specs. See docs for more options."
end
task :default => :help

desc "Force bundling from master"
task :bundle do
  sh('rm -f Gemfile.lock && bundle install --binstubs')
end

desc "Run utlity destroy all machines recipe with chef-provisioning"
task :destroy_all do
  sh('bundle exec chef-client -z -o utility::destroy_all')
end

desc "Build lib and spec yard doc"
task :yardoc do
  sh('bundle exec yardoc spec/* lib/*')
end

desc "Start default yard server"
task :yard_server do
  sh('bundle exec yard server')
end

desc "Clean up chef-repo and test-results"
task :clean do
  sh('rm -rf ./chef-repo ./test-results')
end

desc "Berks vendor and friends"
task :berks do
  sh('rm -rf Berksfile.lock berks-cookbooks; bundle exec berks vendor')
end
