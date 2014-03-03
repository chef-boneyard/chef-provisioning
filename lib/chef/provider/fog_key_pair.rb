require 'chef/provider/lwrp_base'

class Chef::Provider::FogKeyPair < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    create_key
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete #{key_description}" do
        case new_resource.provisioner.compute_options[:provider]
        when 'DigitalOcean'
          compute.destroy_key_pair(@current_id)
        when 'OpenStack'
          compute.key_pairs.destroy(@current_id)
        else
          compute.key_pairs.delete(new_resource.name)
        end
      end
    end
  end

  def key_description
    "#{new_resource.name} on #{new_resource.provisioner.provisioner_url}"
  end

  def create_key
    if current_resource_exists?
      # If the public keys are different, update the server public key
      if !current_resource.private_key_path
        if new_resource.allow_overwrite
          ensure_keys
        else
          raise "#{key_description} already exists on the server, but the private key #{new_resource.private_key_path} does not exist!"
        end
      else
        ensure_keys
      end

      new_fingerprint = case new_resource.provisioner.compute_options[:provider]
      when 'DigitalOcean'
        Cheffish::KeyFormatter.encode(desired_key, :format => :openssh)
      when 'OpenStack'
        Cheffish::KeyFormatter.encode(desired_key, :format => :openssh)
      else
        Cheffish::KeyFormatter.encode(desired_key, :format => :fingerprint)
      end

      if new_fingerprint != @current_fingerprint
        if new_resource.allow_overwrite
          converge_by "update #{key_description} to match local key at #{new_resource.private_key_path}" do
            case new_resource.provisioner.compute_options[:provider]
            when 'DigitalOcean'
              compute.create_ssh_key(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
            when 'OpenStack'
              compute.create_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
            else
              compute.import_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
            end
          end
        else
          raise "#{key_description} does not match local private key, and allow_overwrite is false!"
        end
      end
    else
      # Generate the private and/or public keys if they do not exist
      ensure_keys

      # Create key
      converge_by "create #{key_description} from local key at #{new_resource.private_key_path}" do
        case new_resource.provisioner.compute_options[:provider]
        when 'DigitalOcean'
          compute.create_ssh_key(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
        when 'OpenStack'
          compute.create_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
        else
          compute.import_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
        end
      end
    end
  end

  def ensure_keys
    resource = new_resource
    Cheffish.inline_resource(self) do
      private_key resource.private_key_path do
        public_key_path resource.public_key_path
        if resource.private_key_options
          resource.private_key_options.each_pair do |key,value|
            send(key, value)
          end
        end
      end
    end
  end

  def desired_key
    @desired_key ||= begin
      if new_resource.public_key_path
        public_key, format = Cheffish::KeyFormatter.decode(IO.read(new_resource.public_key_path))
        public_key
      else
        private_key, format = Cheffish::KeyFormatter.decode(IO.read(new_resource.private_key_path))
        private_key.public_key
      end
    end
  end

  def current_resource_exists?
    @current_resource.action != [ :delete ]
  end

  def compute
    new_resource.provisioner.compute
  end

  def current_public_key
    current_resource.source_key
  end

  def load_current_resource
    if !new_resource.provisioner.kind_of?(ChefMetal::Provisioner::FogProvisioner)
      raise 'ec2_key_pair only works with fog_provisioner'
    end
    @current_resource = Chef::Resource::FogKeyPair.new(new_resource.name)
    case new_resource.provisioner.compute_options[:provider]
    when 'DigitalOcean'
      current_key_pair = compute.ssh_keys.select { |key| key.name == new_resource.name }.first
      if current_key_pair
        @current_id = current_key_pair.id
        @current_fingerprint = current_key_pair ? compute.ssh_keys.get(@current_id).ssh_pub_key : nil
      else
        current_resource.action :delete
      end
    when 'OpenStack'
      current_key_pair = compute.key_pairs.get(new_resource.name)
      if current_key_pair
        @current_id = current_key_pair.name
        @current_fingerprint = current_key_pair ? compute.key_pairs.get(@current_id).public_key : nil
      else
        current_resource.action :delete  
      end
    else
      current_key_pair = compute.key_pairs.get(new_resource.name)
      if current_key_pair
        @current_fingerprint = current_key_pair ? current_key_pair.fingerprint : nil
      else
        current_resource.action :delete
      end
    end

    if new_resource.private_key_path && ::File.exist?(new_resource.private_key_path)
      current_resource.private_key_path new_resource.private_key_path
    end
    if new_resource.public_key_path && ::File.exist?(new_resource.public_key_path)
      current_resource.public_key_path new_resource.public_key_path
    end
  end
end
