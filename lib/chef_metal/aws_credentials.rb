module ChefMetal
  # Reads in a credentials file in Amazon's download format and presents the credentials to you
  class AWSCredentials
    def initialize
      @credentials = {}
    end

    def first
      @credentials.first[1]
    end

    def keys
      @credentials.keys
    end

    def [](name)
      @credentials[name]
    end

    def load(credentials_csv_file)
      require 'csv'
      CSV.new(File.open(credentials_csv_file), :headers => :first_row).each do |row|
        @credentials[row['User Name']] = {
          :user_name => row['User Name'],
          :access_key_id => row['Access Key Id'],
          :secret_access_key => row['Secret Access Key']
        }
      end
    end

    def self.method_missing(name, *args, &block)
      singleton.send(name, *args, &block)
    end

    def self.singleton
      @aws_credentials ||= AWSCredentials.new
    end
  end
end
