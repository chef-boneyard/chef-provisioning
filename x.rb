require 'fileutils'

Dir['lib2/chef_provisioning/**/*.rb'].each do |file|
  new_file = file.sub('lib2/chef_provisioning', 'lib/chef_metal')
  puts new_file
  FileUtils.mkdir_p(File.dirname(new_file))
  File.open(new_file, 'w') do |f|
    f.write "require #{file[5..-4].inspect}\n"
  end
end
