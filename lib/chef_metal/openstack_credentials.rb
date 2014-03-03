module ChefMetal
  # Reads in a credentials file
  class OpenstackCredentials
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

    def load_yaml(credentials_yaml_file)
      creds_file = YAML.load(File.expand_path(credentials_yaml_file))
      creds_file.each do |section, creds|
        @credentials[section] = {
          :openstack_username => creds_file[section]['openstack_username'],
          :openstack_api_key => creds_file[section]['openstack_api_key'],
          :openstack_tenant => creds_file[section]['openstack_tenant'],
          :openstack_auth_url => creds_file[section]['openstack_auth_url']
        }
      end
    end

    def load_default
      load_yaml('~/.fog')
    end

    def self.method_missing(name, *args, &block)
      singleton.send(name, *args, &block)
    end

    def self.singleton
      @openstack_credentials ||= OpenstackCredentials.new
    end
  end
end
