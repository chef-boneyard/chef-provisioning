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
        compute.key_pairs.delete(new_resource.name)
      end
    end
  end

  def key_description
    "#{new_resource.name} on #{new_resource.provisioner.provisioner_url}"
  end

  def create_key
    if current_resource_exists?
      # If the public keys are different, update the server public key
      if desired_key && Cheffish::KeyFormatter.encode(desired_key, :format => :fingerprint) != @current_fingerprint
        if new_resource.allow_overwrite
          converge_by "update #{key_description} to match local key at #{new_resource.source_key_path}" do
            compute.import_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
          end
        else
          raise "#{key_description} does not match local private key, and allow_overwrite is false!"
        end
      end
    else
      # Create key
      if desired_key
        converge_by "create #{key_description} from local key at #{new_resource.source_key_path}" do
          compute.import_key_pair(new_resource.name, Cheffish::KeyFormatter.encode(desired_key, :format => :openssh))
        end
      end
    end
  end

  def current_resource_exists?
    @current_resource.action != [ :delete ]
  end

  def compute
    new_resource.provisioner.compute
  end

  def desired_key
    @desired_key ||= begin
      if new_resource.source_key.is_a?(String)
        key, key_format = Cheffish::KeyFormatter.decode(current_key_pair.public_key)
      elsif new_resource.source_key
        key = new_resource.source_key
      elsif new_resource.source_key_path
        key, key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.source_key_path), new_resource.source_key_pass_phrase, new_resource.source_key_path)
      else
        key = nil
      end

      if key && key.private?
        key = key.public_key
      end
      key
    end
  end

  def current_public_key
    current_resource.source_key
  end

  def load_current_resource
    if !new_resource.provisioner.kind_of?(ChefMetal::Provisioner::FogProvisioner)
      raise 'ec2_key_pair only works with fog_provisioner'
    end
    @current_resource = Chef::Resource::FogKeyPair.new(new_resource.name)
    current_key_pair = compute.key_pairs.get(new_resource.name)
    if current_key_pair
      @current_fingerprint = current_key_pair.fingerprint
    else
      current_resource.action :delete
    end
  end
end
