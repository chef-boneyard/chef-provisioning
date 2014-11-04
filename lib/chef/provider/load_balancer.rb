require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/chef_load_balancer_spec'

class Chef
  class Provider
    class LoadBalancer < Chef::Provider::LWRPBase

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      def whyrun_supported?
        true
      end

      def new_driver
        @new_driver ||= run_context.chef_metal.driver_for(new_resource.driver)
      end

      action :create do
        lb_spec = Chef::Provisioning::ChefLoadBalancerSpec.get(new_resource.name) ||
                  Chef::Provisioning::ChefLoadBalancerSpec.empty(new_resource.name)

        Chef::Log.debug "Creating load balancer: #{new_resource.name}; loaded #{lb_spec.inspect}"
        if lb_spec.load_balancer_options
          # Updating
          update_loadbalancer(lb_spec)
        else
          lb_spec.load_balancer_options = new_resource.load_balancer_options
          lb_spec.machines = new_resource.machines
          create_loadbalancer(lb_spec)
        end
      end

      action :destroy do
        lb_spec = Chef::Provisioning::ChefLoadBalancerSpec.get(new_resource.name)
        new_driver.destroy_load_balancer(@action_handler, lb_spec, lb_options)
      end

      attr_reader :lb_spec


      def update_loadbalancer(lb_spec)
        Chef::Log.debug "Updating load balancer: #{lb_spec.id}"
        machines = Hash[
            *(new_resource.machines).collect {
                |machine_name| [machine_name, get_machine_spec(machine_name)]
            }.flatten
        ]
        new_driver.update_load_balancer(action_handler, lb_spec, lb_options, {
                  :machines => machines
                }
            )
        lb_spec.load_balancer_options = new_resource.load_balancer_options
        lb_spec.machines = new_resource.machines
        lb_spec.save(action_handler)
      end

      def create_loadbalancer(lb_spec)
        new_driver.allocate_load_balancer(action_handler, lb_spec, lb_options)
        lb_spec.save(action_handler)
        new_driver.ready_load_balancer(action_handler, lb_spec, lb_options)
      end

      private
      def get_machine_spec(machine_name)
        Chef::Log.debug "Getting machine spec for #{machine_name}"
        Chef::Provisioning::ChefMachineSpec.get(machine_name)
      end

      def lb_options
        new_resource.load_balancer_options
      end

    end
  end
end
