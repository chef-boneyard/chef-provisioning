require 'chef/provider/lwrp_base'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'

class Chef
  class Provider
    class LoadBalancer < Chef::Provider::LWRPBase
      provides :load_balancer

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      def whyrun_supported?
        true
      end

      def new_driver
        @new_driver ||= run_context.chef_provisioning.driver_for(new_resource.driver)
      end

      def chef_managed_entry_store
        @chef_managed_entry_store ||= Provisioning.chef_managed_entry_store(new_resource.chef_server)
      end

      action :create do
        lb_spec = chef_managed_entry_store.get_or_new(:load_balancer, new_resource.name)

        Chef::Log.debug "Creating load balancer: #{new_resource.name}; loaded #{lb_spec.inspect}"
        if new_resource.machines
          machine_specs = new_resource.machines.map { |machine| get_machine_spec!(machine) }
        end

        new_driver.allocate_load_balancer(action_handler, lb_spec, lb_options, machine_specs)
        lb_spec.save(action_handler)
        new_driver.ready_load_balancer(action_handler, lb_spec, lb_options, machine_specs)
      end

      action :destroy do
        lb_spec = chef_managed_entry_store.get(:load_balancer, new_resource.name)
        if lb_spec
          new_driver.destroy_load_balancer(action_handler, lb_spec, lb_options)
        end
      end

      private

      def get_machine_spec!(machine_name)
        Chef::Log.debug "Getting machine spec for #{machine_name}"
        Provisioning.chef_managed_entry_store(new_resource.chef_server).get!(:machine, machine_name)
      end

      def lb_options
        @lb_options ||= begin
          configs = []
          configs << new_resource.load_balancer_options if new_resource.load_balancer_options

          # See documentation in machine.rb provider
          (self.class.additional_lb_option_keys || []).each do |k|
            configs << { k => new_resource.public_send(k)} if new_resource.public_send(k)
          end
          Cheffish::MergedConfig.new(*configs)
        end
      end

      def self.additional_lb_option_keys
        @@additional_lb_option_keys ||= []
      end

    end
  end
end

require 'chef/provisioning/chef_managed_entry_store'
Chef::Provisioning::ChefManagedEntryStore.type_names_for_backcompat[:load_balancer] = "loadbalancers"
