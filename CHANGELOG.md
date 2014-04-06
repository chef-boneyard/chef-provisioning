# Chef Metal Changelog

## 0.7 (4/5/2014)

- Change transport interface: add ability to rewrite URL instead of forwarding ports

## 0.6 (4/4/2014)

- Vagrant and Fog provisioners moved to their own gems (chef-metal-vagrant and chef-metal-fog)
- Support for Hosted and Enterprise Chef (https://github.com/dafyddcrosby)

## 0.5 (4/3/2014)

* Provisioner interface changes designed to allow provisioners to be used outside of Chef (doubt@getchef.com)
  * All Provisioner and Machine methods now take "action_handler" instead of "provider."  It uses the ActionHandler interface described in action_handler.rb.  In short:
    - provider.run_context -> action_handler.recipe_context
    - provider.updated_by_last_action(true) -> action_handler.updated!
    - provider.converge_by -> action_handler.perform_action
    - provider.cookbook_name -> provider.debug_name
  * Convergence strategy: delete_chef_objects() -> cleanup_convergence()
* Ability to get back to a machine from a node (another Provisioner interface change) (doubt@getchef.com):
  * Provisioners must create a file named `chef_metal/provisioner_init/<scheme>_init.rb`.  It will be required when a node is encountered with that scheme.  It should call ChefMetal.add_registered_provisioner_class(<scheme>, <provisioner class name>).  For the provisioner_url `fog:AWS:21348723432`, the scheme is "fog" and the file is `chef_metalprovisioner_init/fog_init.rb`.  It should call `ChefMetal.add_registered_provisioner_class('fog', ChefMetal::Provisioner::FogProvisioner)`.
  * Provisioner classes must implement the class method `inflate(node)`, which should create a Provisioner instance appropriate to the given `node` (generally by looking at `node['normal']['provisioner_output']`)
* New `NoConverge` convergence strategy that creates a node but does not install Chef or converge.
* Support for machine_file `group`, `owner` and `mode` attributes (@irvingpop)
* SSH transport (ryan@segv.net): try to enable pty when possible (increases chance of successful connection).  Set options[:ssh_pty_enable] to `false` to turn this off.  Set `true` to force it (and fail if we can't get it)

## 0.4 (3/29/2014)

* EC2: Make it possible for multiple IAM users to converge chef-metal on the same account
* Openstack: Openstack support via the Fog driver! (@cstewart87)
* EC2: Add :use_private_ip_for_ssh option, and use private ip by default if public IP does not exist.  (@xorl, @dafyddcrosby)
* RHEL/Centos: fix platform detection and installation
