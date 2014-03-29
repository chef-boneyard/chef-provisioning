module ChefMetal
  # Reads in a credentials file in Amazon's download format and presents the credentials to you
  class AWSCredentials
    def initialize
      @credentials = {}
    end

    def default
      @credentials['default'] || @credentials.first[1]
    end

    def keys
      @credentials.keys
    end

    def [](name)
      @credentials[name]
    end

    def load_ini(credentials_ini_file)
      require 'inifile'
      inifile = IniFile.load(File.expand_path(credentials_ini_file))
      inifile.each_section do |section|
        if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
          profile = $1.strip
          @credentials[profile] = {
            :access_key_id => inifile[section]['aws_access_key_id'],
            :secret_access_key => inifile[section]['aws_secret_access_key'],
            :region => inifile[section]['region']
          }
        end
      end
    end

    def load_csv(credentials_csv_file)
      require 'csv'
      CSV.new(File.open(credentials_csv_file), :headers => :first_row).each do |row|
        @credentials[row['User Name']] = {
          :user_name => row['User Name'],
          :access_key_id => row['Access Key Id'],
          :secret_access_key => row['Secret Access Key']
        }
      end
    end

    def load_default
      load_ini('~/.aws/config')
    end

    def self.method_missing(name, *args, &block)
      singleton.send(name, *args, &block)
    end

    def self.singleton
      @aws_credentials ||= AWSCredentials.new
    end
  end
end
