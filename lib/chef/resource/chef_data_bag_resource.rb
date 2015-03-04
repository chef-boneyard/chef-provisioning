require 'chef/resource/lwrp_base'
require 'cheffish'

# A resource that is backed by a data bag in a Chef server somewhere
class Chef::Resource::ChefDataBagResource < Chef::Resource::LWRPBase

  # The key to store this thing under (/data/bag/<<name>>).
  attr_reader :name

  class << self
    # The name of the databag to store the item in.
    attr_reader :databag_name
  end

  def initialize(name, run_context=nil)
    super
    Chef::Log.debug("Re-hydrating #{name} from #{self.class.databag_name}...")
    self.hydrate
  end

  # A list of attributes to be persisted into the databag.
  # @return [Array] List of attributes that are stored in the databag
  def self.stored_attributes
    @stored_attributes || []
  end

  # Set databag name
  # @return [Void]
  def self.databag_name= name
    Chef::Log.debug("Setting databag name to #{name}")
    @databag_name = name
  end

  # Mark an attribute as stored by adding it to the internal tracking list {stored_attributes}
  # and then delegating to {Chef::Resource::LWRPBase#attribute}
  # @param attr_name [Symbol] Name of the attribute as a symbol
  # @return [Void]
  def self.stored_attribute(attr_name, *args)
    @stored_attributes ||= []
    @stored_attributes << attr_name
    self.attribute attr_name, *args
  end

  # Load persisted data from the server's databag. If the databag does not exist on the
  # server, returns nil.
  #
  # @param chef_server [Hash] A hash representing which Chef server to talk to
  # @option chef_server [String] :chef_server_url URL to the Chef server
  # @option chef_server [Hash] :options Options for when talking to the Chef server
  # @option options [String] :client_name The node name making the call
  # @option options [String] :signing_key_filename Path to the signing key
  # @return [Object] an instance of this class re-hydrated from the data hash stored in the
  # databag.
  def hydrate(chef_server = Cheffish.default_chef_server)
    chef_api = Cheffish.chef_server_api(chef_server)
    begin
      data = chef_api.get("/data/#{self.class.databag_name}/#{name}")
      load_from_hash(data)
      Chef::Log.debug("Rehydrating resource from #{self.class.databag_name}/#{name}: #{data}")
    rescue Net::HTTPServerException => e
      if e.response.code == '404'
        nil
      else
        raise
      end
    end
  end

  # Load instance variable data from a hash. For each key,value pair, set @<key> to value
  # @param hash [Hash] Hash containing the instance variable data
  # @return [Object] self after having been populated with data.
  def load_from_hash hash
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)
    end
    self
  end

  # Convert the values in {stored_attributes} to a hash for storing in a databag
  # @return [Hash] a hash of (k,v) pairs where k is each record in {stored_attributes}
  def storage_hash
    ignored = []

    hash = {}
    (self.class.stored_attributes - ignored).each do |attr_name|
      varname = "@#{attr_name.to_s.gsub('@', '')}"
      key = varname.gsub('@', '')
      hash[key] = self.instance_variable_get varname
    end

    hash
  end


  # Save this entity to the server.  If you have significant information that
  # could be lost, you should do this as quickly as possible.
  # @return [Void]
  def save

    create_databag_if_needed self.class.databag_name

    # Clone for inline_resource
    _databag_name = self.class.databag_name
    _hash = self.storage_hash
    _name = self.name

    Cheffish.inline_resource(self, @action) do
      chef_data_bag_item _name do
        data_bag _databag_name
        raw_data _hash
        action :create
      end
    end
  end

  # Delete this entity from the server
  # @return [Void]
  def delete
    # Clone for inline_resource
    _name = self.name
    _databag_name = self.class.databag_name

    Cheffish.inline_resource(self, @action) do
      chef_data_bag_item _name do
        data_bag _databag_name
        action :delete
      end
    end
  end

  def new_resource
    self
  end

  private
  # Create the databag with Cheffish if required
  # @return [Void]
  def create_databag_if_needed databag_name
    _databag_name = databag_name
    Cheffish.inline_resource(self, @action) do
      chef_data_bag _databag_name do
        action :create
      end
    end
  end
end
