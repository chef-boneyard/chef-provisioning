# Chef Provisioning Changelog

## 1.1.1 (4/19/2015)

- Fixed undefined method on nil class error inside setup-convergence ([@tyler-ball][])

## 1.1.0 (4/16/2015)

- Fix machine_batch :destroy, no longer creating extra threads ([#321][])
- Allow user to specify a custom stdout in `Chef::Config[:stdout]` ([#311][])
- If `convergence_options[:bootstrap_proxy]` is populated use it to download chef ([#317][])

## 1.0.1 (4/7/2015)

- Clean up dependencies ([#316][])
- Updating to latest Cheffish

## 1.0.0 (4/2/2015)
## 1.0.0.rc.2 (4/1/2015)

- Fix an issue with vagrant second-converge failing

## 1.0.0.rc.1 (3/31/2015)
## 0.20 (3/27/2015)

- Marking machines `nil` in a load_balancer does not affect existing machines ([#299][])
- `with_driver` now optionally accepts a block.  If passed, it is only active in that block.  If not passed, existing behavior is unchanged.  ([#296][])
- New `show_output` attribute for `machine_execute`, defaults to false ([@causton1][])
- Changed `MachineSpec` storage to `ManagedEntry`.  Driver authors, see PR for details ([#297][])
- If specifying exact chef version, don't re-install every chef-provisioning ([#303][])

## 0.19 (2/25/2015)

- Support for different versions of Chef with the :chef_version and :prerelease arguments (`machine_options convergence_options: { chef_version: '12.0.1' }` or `prerelease: true`)
- Support HTTPS proxy ([@causton1][])
- Automatically configure HTTPS proxy when specifying `machine_options convergence_options: { http_proxy: '...' }`
- Support for arbitrary configuration using `machine_options convergence_options: { chef_config: "anything you want dumped in /etc/chef/client.rb (will be appended to the standard options already placed in the file)" }`

- Make load_balancer :destroy work ([@lynchc][])
- Default to SSL for Chef install download ([@xeon22][])
- Fix Chef overwriting attributes on first converge in `machine_batch` ([#209][])
- Fix node permissions on Hosted / Enterprise Chef: no more adding your clients to the `admins` group (ewww).  ([#59][])
- Always pass an array (never nil) to the driver, even when there are no machines to add to it (partial fix for chef/chef-provisioning-aws[#81][])

## 0.18 (1/27/2015)

- Allow `ssl_verify_mode` to be overridden ([@mivok][])
- Support `machine_options[:convergence_options][:bootstrap_proxy]` ([@mivok][])
- Allow `machine_options[:ssh_gateway]` without username (no @) ([@mivok][])
- Fix issue with net-ssh 2.9.2
- Add `action :destroy` to `machine_image` ([@miguelcnf][])

## 0.17 (12/17/2014)

- Make machine batch convergent
- Consolidate load balancer create and update
- Update some URLs
- SSL verification fix
- Test suites
- Auto-create image data bags
- Remove some un-needed dependencies
- Wipe out SSH keys in debug messages

## 0.16 (11/4/2014)

- Make it work with Chef 12

## 0.15.2 (11/4/2014)

- Remove Chef as a dependency so that it can be a dep of Chef

## 0.15.1 (10/30/2014)

- Make syntax error go away, grr.

## 0.15 (10/29/2014)

- Rename from chef-metal to chef-provisioning

## 0.14.2 (9/2/2014)

- Disable auto batching
- Fix for with_machine_options context hash
- Pass timeout from execution_options to winrm set_timeout
- Add better error message when driver does not specify driver_url
- Add info that location.driver_url is required
- Remove Chef 11.14 alpha note in readme
- Gracefully handle Host Down and Network Unreachable

## 0.14.1 (8/18/2014)

- Fix "metal execute mario ls" to work again

## 0.14 (8/18/2014)

- FEATURE: Add the machine_image resource ([@jkeiser][], [@johnewart][]):
  ```ruby
  machine_image 'base' do
    machine_options :bootstrap_options => { :image_id => 'ami-1234798123431', :ssh_username => 'root' }
    recipe 'secure_base'
    recipe 'corp_users'
  end
  # Build an image based on 'base' that has apache
  machine_image 'apache' do
    # All bootstrap options, like ssh_username, are carried forward
    from_image 'base'
    recipe 'apache2'
  end
  # Build an image with my web app based on the apache base image
  machine_image 'myapp' do
    from_image 'apache'
    recipe 'mywebapp'
  end
  # Build an image with mysql and my schema based on the corporate base image
  machine_image 'mydb' do
    from_image 'base'
    recipe 'mysql'
    recipe 'myschema'
  end
  # Build a DB machine from mydb.  Does not reinstall stuff! :)
  machine 'db' do
    from_image 'mydb'
  end
  # Build a web app machine from myapp.  Does not reinstall stuff! :)
  machine 'myapp1' do
    from_image 'myapp'
  end
  ```
  - Creates a node with the name of the machine_image, which contains metadata
    like the username of the image.  This makes things like AWS image registries
    possible.
- Fix the no_converge convergence strategy ([@johnewart][])
- SSH port forwarding improvements:
  - Detects *any* IP on the localhost and forwards it--not just 127.0.0.1
  - Binds to localhost on the remote side instead of 127.0.0.1, allowing for IPv6 communication
  - Tries multiple ports--if the origin port is already taken, tries "0" (ephemeral).
- Fix SSH race condition causing port forwarding to happen twice (and fail miserably)
- Add Chef::Provisioning.connect_to_machine('mario')

## 0.13 (6/17/2014)

- make winrm work again ([@mwrock][])
- add bootstrap_proxy as a convergence_option for when target machines require a proxy ([@MrMMorris][])

## 0.12.1 (6/18/2014)

- fix machine_batch action :setup
- fix issue with default machine_batch names being non-unique across recipes

## 0.12 (6/18/2014)

- Remove chef-provisioning-fog and chef-provisioning-vagrant as dependencies (install whatever things you want directly!)
- Fix ssl_verify_mode to work correctly when other HTTPS calls are made ([@mwrock][])
- Fix machine_file and machine_execute resources ([@irvingpop][])

## 0.11.2 (6/4/2014)

- Fix issue where machines with different drivers could get default options from the global current driver

## 0.11.1 (6/4/2014)

- fix local mode port forwarding on IPv6 hosts

## 0.11 (6/4/2014)

- New Driver interface (see docs/ and blogs/ directories for documentation)
- New configuration (see docs/ and blogs/)
- get rid of annoying SSL warning (note: this turns off SSL verification, which was the default anyway)
- fix machine_batch error report to be less verbose
- fail when machine is being moved from driver to driver
- [@marcusn][] disconnect from SSH when there is a problem
- fix SSH gateway code to honor any options given ([@marcusn][])
- Make machine_batch auto batching smarter (only batch things that have the same actions)
- Allow auto batching to be turned off with `auto_batch_machines = false` in recipes or config
- Allow this:
  ```ruby
  machine_batch do
    machine 'a'
    machine 'b'
  end
  ```
- Allow this:
  ```ruby
  machine_batch do
    machines 'a', 'b', 'c'
    action :destroy
  end
  ```
- fix issue setting Hosted Chef ACLs on nodes
- fix local mode forwarding in mixed IPv4/IPv6 environments

## 0.10.2 (5/2/2014)

- Fix crash with add_provisioner_options when provisioner_options is not yet set

## 0.10.1 (5/2/2014)

- Fix a crash when uploading files in a machine batch

## 0.10 (5/1/2014)

- Parallelism!
  - All machines by default will be created in parallel just before the first "machine" definition. They will attempt to run all the way to converge.  If they fail, add "with_machine_batch 'mybatch', :setup"
  - Use "with_machine_batch 'mybatch'" before any machines if you want tighter control. Actions include :delete, :acquire, :setup, and :converge.
- Parallelizableness: chef-provisioning now stores data in the run_context instead of globally, so that it can be run multiple times in parallel. This capability is not yet being used.

## 0.9.4 (4/23/2014)

- Preserve provisioner_output in machine resource (don't destroy it!!)

## 0.9.3 (4/13/2014)

- SSH: Treat EHOSTUNREACH as "machine not yet available" (helps with AWS)

## 0.9.2 (4/13/2014)

- Timeout stability fixes (makes EC2 a little stabler for some AMIs)

## 0.9.1 (4/11/2014)

- Make write_file and upload_file create parent directory

## 0.9 (4/9/2014)

- Add `files` and `file` attributes to the `machine` resource
- Fix `machine_execute` resource ([@irvingpop][])
- Fix `machine :converge` action (thanks [@double-z][])
- Make chef-client timeout longer by default (2 hours)
- Make chef_client_timeout a configurable option for all convergence strategies and provisioner_options
- Add `metal cp` command

## 0.8.2 (4/9/2014)

- Add timeout support to execute
- Fix machine_file resource
- Add ohai_hints DSL to machine resource ([@xorl][])

## 0.8.1 (4/9/2014)

- Bug: error! was not raising an error in the SSH and WinRM transports
- Transports: stream output automatically when in debug
- Support the :read_only execute hint (for Docker)
- Add more metal command lines (converge, update, delete)
- Add Chef::Provisioning.connect_to_machine(machine_name) method to get Machine object for a node name

## 0.8 (4/8/2014)

- New machine_execute resource! (irving[@chef][].io)
- Experimental "metal" command line: metal execute NODENAME COMMAND ARGS
- Transport: Add ability to stream execute() for better nested chef-client debugging

## 0.7 (4/5/2014)

- Change transport interface: add ability to rewrite URL instead of forwarding ports

## 0.6 (4/4/2014)

- Vagrant and Fog provisioners moved to their own gems (chef-provisioning-vagrant and chef-provisioning-fog)
- Support for Hosted and Enterprise Chef (https://github.com/dafyddcrosby)

## 0.5 (4/3/2014)

* Provisioner interface changes designed to allow provisioners to be used outside of Chef (doubt[@chef][].io)
  * All Provisioner and Machine methods now take "action_handler" instead of "driver."  It uses the ActionHandler interface described in action_handler.rb.  In short:
    - driver.run_context -> action_handler.recipe_context
    - driver.updated_by_last_action(true) -> action_handler.updated!
    - driver.converge_by -> action_handler.perform_action
    - driver.cookbook_name -> driver.debug_name
  * Convergence strategy: delete_chef_objects() -> cleanup_convergence()
* Ability to get back to a machine from a node (another Provisioner interface change) (doubt[@chef][].io):
  * Provisioners must create a file named `chef_provisioning/provisioner_init/<scheme>_init.rb`.  It will be required when a node is encountered with that scheme.  It should call Chef::Provisioning.add_registered_provisioner_class(<scheme>, <provisioner class name>).  For the provisioner_url `fog:AWS:21348723432`, the scheme is "fog" and the file is `chef_provisioningprovisioner_init/fog_init.rb`.  It should call `Chef::Provisioning.add_registered_provisioner_class('fog', Chef::Provisioning::Provisioner::FogProvisioner)`.
  * Provisioner classes must implement the class method `inflate(node)`, which should create a Provisioner instance appropriate to the given `node` (generally by looking at `node['normal']['provisioner_output']`)
* New `NoConverge` convergence strategy that creates a node but does not install Chef or converge.
* Support for machine_file `group`, `owner` and `mode` attributes ([@irvingpop][])
* SSH transport (ryan[@segv][].net): try to enable pty when possible (increases chance of successful connection).  Set options[:ssh_pty_enable] to `false` to turn this off.  Set `true` to force it (and fail if we can't get it)

## 0.4 (3/29/2014)

* EC2: Make it possible for multiple IAM users to converge chef-provisioning on the same account
* Openstack: Openstack support via the Fog driver! ([@cstewart87][])
* EC2: Add :use_private_ip_for_ssh option, and use private ip by default if public IP does not exist.  ([@xorl][], [@dafyddcrosby][])
* RHEL/Centos: fix platform detection and installation

<!--- The following link definition list is generated by PimpMyChangelog --->
[#59]: https://github.com/chef/chef-provisioning/issues/59
[#81]: https://github.com/chef/chef-provisioning/issues/81
[#209]: https://github.com/chef/chef-provisioning/issues/209
[#296]: https://github.com/chef/chef-provisioning/issues/296
[#297]: https://github.com/chef/chef-provisioning/issues/297
[#299]: https://github.com/chef/chef-provisioning/issues/299
[#303]: https://github.com/chef/chef-provisioning/issues/303
[#311]: https://github.com/chef/chef-provisioning/issues/311
[#316]: https://github.com/chef/chef-provisioning/issues/316
[#317]: https://github.com/chef/chef-provisioning/issues/317
[#321]: https://github.com/chef/chef-provisioning/issues/321
[@MrMMorris]: https://github.com/MrMMorris
[@causton1]: https://github.com/causton1
[@chef]: https://github.com/chef
[@cstewart87]: https://github.com/cstewart87
[@dafyddcrosby]: https://github.com/dafyddcrosby
[@double-z]: https://github.com/double-z
[@irvingpop]: https://github.com/irvingpop
[@jkeiser]: https://github.com/jkeiser
[@johnewart]: https://github.com/johnewart
[@lynchc]: https://github.com/lynchc
[@marcusn]: https://github.com/marcusn
[@miguelcnf]: https://github.com/miguelcnf
[@mivok]: https://github.com/mivok
[@mwrock]: https://github.com/mwrock
[@segv]: https://github.com/segv
[@tyler-ball]: https://github.com/tyler-ball
[@xeon22]: https://github.com/xeon22
[@xorl]: https://github.com/xorl