require 'chef/resource/lwrp_base'
require 'cheffish'
require 'chef/provisioning'
require 'cheffish/merged_config'

class Chef
class Resource
class Machine < Chef::Resource::LWRPBase

  self.resource_name = 'machine'

  def initialize(*args)
    super
    @chef_environment = run_context.cheffish.current_environment
    @chef_server = run_context.cheffish.current_chef_server
    @driver = run_context.chef_provisioning.current_driver
    @machine_options = run_context.chef_provisioning.current_machine_options
  end

  actions :allocate, :ready, :ready_only, :setup, :converge, :converge_only, :destroy, :stop
  default_action :converge

  # Driver attributes
  attribute :driver

  # Machine options
  attribute :machine_options

  # This includes attributes from the Cheffish::Node resources - allows us
  # to specify things like `run_list`, `chef_server`, etc.
  Cheffish.node_attributes(self)

  # Client keys
  # Options to generate private key (size, type, etc.) when the server doesn't have it
  attribute :private_key_options, :kind_of => Hash
  attribute :allow_overwrite_keys, :kind_of => [TrueClass, FalseClass]

  # Optionally pull the public key out to a file
  attribute :public_key_path, :kind_of => String
  attribute :public_key_format, :kind_of => String

  # If you really want to force the private key to be a certain key, pass these
  attribute :source_key
  attribute :source_key_path, :kind_of => String
  attribute :source_key_pass_phrase

  # Client attributes
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :validator, :kind_of => [TrueClass, FalseClass]

  # Client Ohai hints, allows machine to enable hints
  # e.g. ohai_hints 'ec2' => { 'a' => 'b' } creates file ec2.json with json contents { 'a': 'b' }
  attribute :ohai_hints, :kind_of => Hash

  # A string containing extra configuration for the machine
  attribute :chef_config, :kind_of => String

  # Allows you to turn convergence off in the :create action by writing "converge false"
  # or force it with "true"
  attribute :converge, :kind_of => [TrueClass, FalseClass]

  # A list of files to upload, in the format REMOTE_PATH => LOCAL_PATH|HASH.
  # == Examples
  # files '/remote/path.txt' => '/local/path.txt'
  # files '/remote/path.txt' => { :local_path => '/local/path.txt' }
  # files '/remote/path.txt' => { :content => 'woo' }
  attribute :files, :kind_of => Hash

  # The named machine_image to start from.  Specify the name of a machine_image
  # object and the default machine_options will be set to use that image.
  # == Examples
  # from_image 'company_base_image'
  attribute :from_image, :kind_of => String

  # A single file to upload, in the format REMOTE_PATH, LOCAL_PATH|HASH.
  # This directive may be passed multiple times, and multiple files will be uploaded.
  # == Examples
  # file '/remote/path.txt', '/local/path.txt'
  # file '/remote/path.txt', { :local_path => '/local/path.txt' }
  # file '/remote/path.txt', { :content => 'woo' }
  def file(remote_path, local = nil)
    @files ||= {}
    if remote_path.is_a?(Hash)
      if local
        raise "file(Hash, something) does not make sense.  Either pass a hash, or pass a pair, please."
      end
      remote_path.each_pair do |remote, local|
        @files[remote] = local
      end
    elsif remote_path.is_a?(String)
      if !local
        raise "Must pass both a remote path and a local path to file directive"
      end
      @files[remote_path] = local
    else
      raise "file remote_path must be a String, but is a #{remote_path.class}"
    end
  end

  def add_machine_options(options)
    @machine_options = Cheffish::MergedConfig.new(options, @machine_options)
  end


  # This is here because provisioning users will probably want to do things like:
  # machine "foo"
  #   action :destroy
  # end
  #
  # @example
  #   with_machine_options :bootstrap_options => { ... }
  #   machine "foo"
  #     converge true
  #   end
  #
  # Without this, the first resource's machine options will obliterate the second
  # resource's machine options, and then unexpected (and undesired) things happen.
  def load_prior_resource(*args)
    Chef::Log.debug "Overloading #{self.resource_name} load_prior_resource with NOOP"
  end

  # chef client version and omnibus
  # chef-zero boot method?
  # chef-client -z boot method?
  # pushy boot method?
end
end
end
