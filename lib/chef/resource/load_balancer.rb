require 'chef/resource/lwrp_base'
require 'cheffish'
require 'chef_metal'
require 'cheffish/merged_config'

class Chef
  class Resource
    class LoadBalancer < Chef::Resource::LWRPBase

      self.resource_name = 'load_balancer'

      def initialize(*args)
        super
        @chef_environment = run_context.cheffish.current_environment
        @chef_server = run_context.cheffish.current_chef_server
        @driver = run_context.chef_metal.current_driver
        @load_balancer_options = run_context.chef_metal.current_load_balancer_options
      end

      actions :create, :destroy
      default_action :create

      # Driver attributes
      attribute :driver
      attribute :chef_server
      attribute :load_balancer_options
      attribute :name, :kind_of => String, :name_attribute => true
      attribute :machines

      def add_load_balancer_options(options)
        @load_balancer_options = Cheffish::MergedConfig.new(options, @load_balancer_options)
      end


      # This is here because metal users will probably want to do things like:
      # machine "foo"
      #   action :destroy
      # end
      #
      # with_load_balancer_options :bootstrap_options => {...}
      # machine "foo"
      #   converge true
      # end
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
