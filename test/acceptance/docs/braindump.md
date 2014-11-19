## Chef Metal Drivers
https://github.com/opscode?query=chef-metal
“opscode”
### cloud drivers
remember:  cloud drivers cost money!
* aws
* azure
* fog
 * ec2
 * rackspace
 * digitalocean
 * openstack
 
### vm and container drivers
* docker
* vagrant
 * virtualbox
 * vmware
* lxc
* vsphere (3rd party)

what is hanlon?

## OS Node Support
(Note: Chef Server 12 will be the only supported server host version)
* ubuntu 10.04, 12.04, 14.04
* centos 5, 6, 7
* i386, x64
* windows versions?

## Provisioning Paths
(priority order)
* unix from unix
* windows from windows
* windows from unix
* unix from windows

## Chef Server Types
* chef-zero
* hosted - dedicated org
* server - need to provision a cluster (recommend chef-server-cluster)

## Special Cases
* parallelization for cloud only
 * how to test concurrent in-flight instances?
* cloud idempotence
 * :allocate
 * :ready
 * :converge
* machine image resources
 * creating an image
 * load from image
* Cleanup

## Planning

### Prioritize initial RC work for AWS re-invent
* Combinators
 * drivers (applicable sub-providers)
 * OSs
 * Server type
 * Provisioning paths
* Not in order. In fact, the combinations will likely be mixed

### All drivers must be supported (eventually)
* will need subscriptions for cloud providers

### Braindump for automated testing harness
* Separate recipes for server types, drivers, os selection, smoke test, and special cases so tests can be pieced together to generate most (if not all) of the valid combinations
* Maybe each test can just create nodes of each OS (when applicable)
* Tests will be run with rspec
* Collect existing examples from doc and tests to create the smoke test recipes

