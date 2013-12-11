require 'chef_metal'

class Chef::Resource::FogKeyPair < Chef::Resource::LWRPBase
  self.resource_name = 'fog_key_pair'

  def initialize(*args)
    super
    @provisioner = ChefMetal.enclosing_provisioner
  end

  actions :create, :delete, :nothing
  default_action :create

  attribute :provisioner
  attribute :source_key
  attribute :source_key_path, :kind_of => String
  attribute :source_key_pass_phrase
  # TODO what is the right default for this?
  attribute :allow_overwrite, :kind_of => [TrueClass, FalseClass], :default => false

  # Proc that runs after the resource completes.  Called with (resource, private_key, public_key)
  def after(&block)
    block ? @after = block : @after
  end
end
