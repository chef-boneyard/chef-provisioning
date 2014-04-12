require 'chef/version_class'

class ::TestHelper
  def self.source_path(gem_name)
    "#{ENV['HOME']}/oc/code/opscode/#{gem_name}"
  end

  def self.build_latest_gem_files(recipe, *gem_names)
    gem_names.flatten.each do |gem_name|
      recipe.execute "rake build" do
        cwd TestHelper.source_path(gem_name)
      end
    end
  end

  def self.upload_latest_gem_files(machine, *gem_names)
    gem_names.flatten.each do |gem_name|
      latest = nil
      Dir.glob("#{source_path(gem_name)}/pkg/*.gem").each do |gemfile|
        next if File.basename(gemfile) !~ /^#{gem_name}-(\d+\.\d+(\.\d+)?)\.gem$/
        version_str = $1
        version = Chef::Version.new(version_str)
        if latest
          if (version <=> latest[0]) > 0
            latest = [ version, version_str, gemfile ]
          end
        else
          latest = [ version, version_str, gemfile ]
        end
      end
      if latest
        version, version_str, gemfile = latest
        machine.file "/tmp/packages_from_host/#{File.basename(gemfile)}", gemfile
      else
        Chef::Log.warn "No gemfile found in #{source_path(gem_name)}/pkg.  Skipping ..."
      end
    end
  end

  def self.install_latest_gem(recipe, gem_name, path)
    latest = nil
    Dir.glob("#{path}/*.gem").each do |gemfile|
      next if File.basename(gemfile) !~ /^#{gem_name}-(\d+\.\d+(\.\d+)?)\.gem$/
      version_str = $1
      version = Chef::Version.new(version_str)
      if latest
        if (version <=> latest[0]) > 0
          latest = [ version, version_str, gemfile ]
        end
      else
        latest = [ version, version_str, gemfile ]
      end
    end
    if latest
      recipe.chef_gem gem_name do
        source latest[2]
        version latest[1]
        action :upgrade # TODO this probably won't overwrite the existing package if we update the .gem with the same version.  Force?
      end
    else
      Chef::Log.warn("#{gem_name} not found at #{path}.  Installing #{gem_name} from rubygems.")
      recipe.chef_gem gem_name do
        action :upgrade
      end
    end
  end
end
