module RepositorySupport
  def when_the_repository(desc, *tags, &block)
    context("when the chef repo #{desc}", *tags) do
      include_context "with a chef repo"
      extend WhenTheRepositoryClassMethods
      module_eval(&block)
    end
  end

  RSpec.shared_context "with a chef repo" do
    before :each do
      raise "Can only create one directory per test" if @repository_dir
      @repository_dir = Dir.mktmpdir('chef_repo')
      Chef::Config.chef_repo_path = @repository_dir
      %w(client cookbook data_bag environment node role user).each do |object_name|
        Chef::Config.delete("#{object_name}_path".to_sym)
      end
    end

    after :each do
      if @repository_dir
        begin
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config.delete("#{object_name}_path".to_sym)
          end
          Chef::Config.delete(:chef_repo_path)
          FileUtils.remove_entry_secure(@repository_dir)
        ensure
          @repository_dir = nil
        end
      end
      Dir.chdir(@old_cwd) if @old_cwd
    end

    def directory(relative_path, &block)
      old_parent_path = @parent_path
      @parent_path = path_to(relative_path)
      FileUtils.mkdir_p(@parent_path)
      instance_eval(&block) if block
      @parent_path = old_parent_path
    end

    def file(relative_path, contents)
      filename = path_to(relative_path)
      dir = File.dirname(filename)
      FileUtils.mkdir_p(dir) unless dir == '.'
      File.open(filename, 'w') do |file|
        raw = case contents
              when Hash
                JSON.pretty_generate(contents)
              when Array
                contents.join("\n")
              else
                contents
              end
        file.write(raw)
      end
    end

    def symlink(relative_path, relative_dest)
      filename = path_to(relative_path)
      dir = File.dirname(filename)
      FileUtils.mkdir_p(dir) unless dir == '.'
      dest_filename = path_to(relative_dest)
      File.symlink(dest_filename, filename)
    end

    def path_to(relative_path)
      File.expand_path(relative_path, (@parent_path || @repository_dir))
    end

    def cwd(relative_path)
      @old_cwd = Dir.pwd
      Dir.chdir(path_to(relative_path))
    end

    module WhenTheRepositoryClassMethods
      def directory(*args, &block)
        before :each do
          directory(*args, &block)
        end
      end

      def file(*args, &block)
        before :each do
          file(*args, &block)
        end
      end

      def symlink(*args, &block)
        before :each do
          symlink(*args, &block)
        end
      end

      def path_to(*args, &block)
        before :each do
          file(*args, &block)
        end
      end
    end
  end
end
