require 'inifile'
require 'csv'

module ChefMetalFog
  module Providers
    class AWS
      # Reads in a credentials file in Amazon's download format and presents the credentials to you
      class Credentials
        def initialize
          @credentials = {}
        end

        include Enumerable

        def default
          if @credentials.size == 0
            raise "No credentials loaded!  Do you have a ~/.aws/config?"
          end
          @credentials[ENV['AWS_DEFAULT_PROFILE'] || 'default'] || @credentials.first[1]
        end

        def keys
          @credentials.keys
        end

        def [](name)
          @credentials[name]
        end

        def each(&block)
          @credentials.each(&block)
        end

        def load_ini(credentials_ini_file)
          inifile = IniFile.load(File.expand_path(credentials_ini_file))
          if inifile
            inifile.each_section do |section|
              if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
                profile_name = $1.strip
                profile = inifile[section].inject({}) do |result, pair|
                  result[pair[0].to_sym] = pair[1]
                  result
                end
                profile[:name] = profile_name
                @credentials[profile_name] = profile
              end
            end
          else
            # Get it to throw an error
            File.open(File.expand_path(credentials_ini_file)) do
            end
          end
        end

        def load_csv(credentials_csv_file)
          CSV.new(File.open(credentials_csv_file), :headers => :first_row).each do |row|
            @credentials[row['User Name']] = {
              :name => row['User Name'],
              :user_name => row['User Name'],
              :aws_access_key_id => row['Access Key Id'],
              :aws_secret_access_key => row['Secret Access Key']
            }
          end
        end

        def load_default
          config_file = ENV['AWS_CONFIG_FILE'] || File.expand_path('~/.aws/config')
          if File.file?(config_file)
            load_ini(config_file)
          end
        end

        def self.method_missing(name, *args, &block)
          singleton.send(name, *args, &block)
        end

        def self.singleton
          @aws_credentials ||= Credentials.new
        end
      end
    end
  end
end
