[![Stories in Ready](https://badge.waffle.io/chef/chef-provisioning.png?label=ready&title=Ready)](https://waffle.io/chef/chef-provisioning)
Chef Provisioning
==========
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/chef/chef-provisioning?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This library solves the problem of repeatably creating machines and infrastructures in Chef.  It has a plugin model that lets you write bootstrappers for your favorite infrastructures, including VirtualBox, EC2, LXC, bare metal, and many more!

[This video](https://www.youtube.com/watch?v=Yb8QdL30WgM) explains the basics of chef-provisioning (though provisioners are now called drivers).  Slides (more up to date) are [here](http://slides.com/jkeiser/chef-metal).

Date       | Blog
-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------
2014-12-15 | [Using Chef Provisioning to Build Chef Server](https://www.chef.io/blog/2014/12/15/sysadvent-day-14-using-chef-provisioning-to-build-chef-server/)
2014-11-12 | [Chef Launches Policy-Based Provisioning](https://www.chef.io/blog/2014/11/12/chef-launches-policy-based-provisioning/)
2014-11-12 | [Chef Provisioning: Infrastructure As Code](https://www.chef.io/blog/2014/11/12/chef-provisioning-infrastructure-as-code/)
2014-06-03 | [machine_batch and parallelization](https://github.com/chef/chef-provisioning/blob/master/docs/blogs/2012-05-28-machine_batch.html.markdown#chef-provisioning-parallelization)
2014-06-03 | [Chef Provisioning, Configuration and Drivers](https://github.com/chef/chef-provisioning/blob/master/docs/blogs/2012-05-22-new-driver-interface.html.markdown#chef-provisioning-configuration-and-drivers)
2014-03-04 | [Chef Metal 0.2: Overview](http://www.chef.io/blog/2014/03/04/chef-metal-0-2-release/) - this is a pretty good overview (though dated).
2013-12-20 | [Chef Metal Alpha](http://www.chef.io/blog/2013/12/20/chef-metal-alpha/)

Documentation
-------------
* [Chef Docs](https://docs.chef.io/provisioning.html)
* [Frequently Asked Questions](https://github.com/chef/chef-provisioning/blob/master/docs/faq.md)
* [Configuration](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#configuring-and-using-provisioning-drivers)
* [Writing Drivers](https://github.com/chef/chef-provisioning/blob/master/docs/building_drivers.md#writing-drivers)
* [Embedding](https://github.com/chef/chef-provisioning/blob/master/docs/embedding.md)
* [Providers](https://github.com/chef/chef-provisioning/blob/master/docs/providers)

Try It Out
----------

You can try out Chef Provisioning in many different flavors.

### Vagrant

To give it a spin, install Vagrant and VirtualBox and try this from the `chef-provisioning/docs/examples` directory:

```
gem install chef-provisioning chef-provisioning-vagrant
export CHEF_DRIVER=vagrant
chef-client -z vagrant_linux.rb simple.rb
```

This will create two vagrant precise64 linux boxes, "mario" and "luigi1", in `~/machinetest`, bootstrapped to an empty runlist.  For Windows, you can replace `myapp::linux` with `myapp::windows`, but you'll need your own Windows vagrant box to do that (licensing!).

### AWS

If you have an AWS account, you can spin up a machine there like this:

```
gem install chef-provisioning chef-provisioning-fog
export CHEF_DRIVER=aws
chef-client -z simple.rb
```

This will create two linux boxes in the AWS account referenced by your default profile in `~/.aws/config` (or your environment variables).

### DigitalOcean

If you are on DigitalOcean and using the `tugboat` gem, you can do this:

```
gem install chef-provisioning chef-provisioning-fog
export CHEF_DRIVER=fog:DigitalOcean
chef-client -z simple.rb
```

If you aren't using the `tugboat` gem, you can put `driver` and `driver_options` into your `.chef/knife.rb` file.

This will use your tugboat settings to create whatever sort of instance you normally create.

### Cleaning up

When you are done with the examples, run this to clean up:

```
chef-client -z destroy_all.rb
```

What Is Chef Provisioning?
-------------------

Chef Provisioning has two major abstractions: the machine resource, and drivers.

### The `machine` resource

You declare what your machines do (recipes, tags, etc.) with the `machine` resource, the fundamental unit of Chef Provisioning.  You will typically declare `machine` resources in a separate, OS/provisioning-independent file that declares the *topology* of your app--your machines and the recipes that will run on them.

The machine resources from the [cluster.rb example](https://github.com/chef/chef-provisioning/blob/master/docs/examples/cluster.rb) are pretty straightforward.  Here's a copy/paste:

```ruby
# Database!
machine 'mario' do
  recipe 'postgresql'
  recipe 'mydb'
  tag 'mydb_master'
end

num_webservers = 1

# Web servers!
1.upto(num_webservers) do |i|
  machine "luigi#{i}" do
    recipe 'apache'
    recipe 'mywebapp'
  end
end
```

You will notice the dynamic nature of the number of web servers.  It's all code, your imagination is the limit :)

### Drivers

Drivers handle the real work of getting those abstract definitions into real, physical form.  They handle the following tasks, idempotently (you can run the resource again and again and it will only create the machine once--though it may notice things are wrong and fix them!):

* Acquiring machines from the cloud, creating containers or VMs, or grabbing bare metal
* Connecting to those machines via ssh, winrm, or other transports
* Bootstrapping chef onto the machines and converging the recipes you suggested

The driver API is separated out so that new drivers can be made with minimal effort (without having to rewrite ssh, tunneling, bootstrapping, and OS support).  But to the user, they appear as a single thing, so that the machine acquisition can use its smarts to autodetect the other bits (transports, OS's, etc.).

Drivers save their data in the Chef node itself, so that they will be accessible to everyone who is using the Chef server to manage the nodes.

Drivers each have their own repository.  Current drivers:

**Cloud:**
- [AWS](https://github.com/chef/chef-provisioning-aws)
- [Azure](https://github.com/chef/chef-provisioning-azure)
- [FOG: EC2, DigitalOcean, OpenStack, etc.](https://github.com/chef/chef-provisioning-fog)

**Virtualization:**
- [Vagrant: VirtualBox, VMWare Fusion, etc.](https://github.com/chef/chef-provisioning-vagrant)
- [VSphere](https://github.com/RallySoftware-cookbooks/chef-metal-vsphere) (not yet up to date with 0.11)

**Containers:**
- [Docker](https://github.com/chef/chef-provisioning-docker)
- [LXC](https://github.com/chef/chef-provisioning-lxc)

**Bare Metal:**
- [Hanlon](https://github.com/chef/chef-provisioning-hanlon)
- [OpenCrowbar](https://github.com/newgoliath/chef-provisioning-crowbar) OpenCrowbar controls your real metal.  It discovers, inventories, configs RAID & BIOS and networks, and installs your OS.  [OpenCrowbar website](http://www.opencrowbar.org) [OpenCrowbar github](https://github.com/opencrowbar/core)
- [SSH (no PXE)](https://github.com/double-z/chef-metal-ssh) (not yet up to date with 0.11)

### Anatomy of a Recipe

chef-zero comes with a provisioner for Vagrant, an abstraction that covers VirtualBox, VMWare and other Virtual Machine drivers. In docs/examples, you can run this to try it:

```ruby
export CHEF_DRIVER=vagrant
chef-client -z vagrant_linux.rb simple.rb
```

This is a chef-client run, which runs multiple **recipes.** Chef Provisioning is nothing but resources you put in recipes.

The driver is specified on the command line.  Drivers are URLs.  You could use `vagrant:~/vms` or `fog:AWS:default:us-east-1' as driver URLs.  More information [here.](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#setting-the-driver-with-a-driver-url)

The `vagrant_linux.rb` recipe handles the physical specification of the machines and Vagrant box:

```ruby
require 'chef/provisioning/vagrant_driver'

vagrant_box 'precise64' do
  url 'http://files.vagrantup.com/precise64.box'
end

with_machine_options :vagrant_options => {
  'vm.box' => 'precise64'
}
```

`require 'chef/provisioning/vagrant_driver'` is how we bring in the `vagrant_box` resource.

`vagrant_box` makes sure a particular vagrant box exists, and lets you specify `machine_options` for things like port forwarding, OS definitions, and any other vagrant-isms.

Typically, you declare these in separate files from your machine resources.  Chef Provisioning picks up the drivers and machine_options you have declared, and uses them to instantiate the machines you request.  The actual machine definitions, in this case, are in `simple.rb`, and are generic--you could use them against Azure or EC2 as well:

```ruby
machine 'mario' do
  tag 'itsame'
end
```

Other directives, like `recipe 'apache'`, help you set run lists and other information about the machine.

### Fog (EC2, Openstack and friends)

chef-provisioning also comes with a [Fog](http://fog.io/) provisioner that handles provisioning to Openstack, Rackspace, Amazon's EC2 and other cloud drivers.  Before you begin, you will need to put your AWS credentials in ~/.aws/config in the format [mentioned in Option 1 here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#d0e726).  There are other ways to specify your credentials, but this is the standard one for the Amazon CLI.

Once your credentials are in, basic usage looks like this:

```
export CHEF_DRIVER=fog:AWS
chef-client -z simple.rb
```

Other valid URLs include `fog:AWS:myprofilename` and `fog:AWS:profilename:us-west-2`.

Most Chef Provisioning drivers try hard to provide reasonable defaults so you can get started easily.  Once you have specified your credentials, AMIs and other things are chosen for you.

You will usually want to create or input a custom key pair for bootstrap. To customize, specify keys and AMI and other options, you can make recipes like this:

```ruby
require 'chef/provisioning/fog_driver'

fog_key_pair 'my_bootstrap_key'

with_machine_options :bootstrap_options => {
  :key_name => 'my_bootstrap_key',
  :image_id => 'ami-59a4a230',
  :flavor_id => 't1.micro'
}
```

`fog_key_pair` creates a new key pair (if the files do not already exist) and uploads it to AWS (it will toss an error if the key pair already exists and does not match). By default, `fog_key_pair` will look for matching key files in .chef/keys, ~/.chef/keys and ~/.ssh.  If it does not find one, it will place the key in `.chef/keys`.  You can override this path in fog_key_pair, but if you do, you will want to modify `private_key_paths` in your configuration to match.

`with_machine_options` specifies machine_options that will be applied to any `machine` resources chef-client encounters.

You will notice that we are still using `simple.rb` here.  Machine definitions are generally driver-independent.  This is an important feature that allows you to spin up your clusters in different places to create staging, test or miniature dev environments.

### Pointing Boxes at Chef Servers

By default, Chef Provisioning will put your boxes on the same Chef server you started chef-client with (in the case of -z, that's a local chef-zero server). Sometimes you want to put your boxes on different servers.  There are a couple of ways to do that:

```ruby
with_chef_local_server :chef_repo_path => '~/repo'
```

`with_chef_local_server` is a generic directive that creates a chef-zero server pointed at the given repository.  nodes, clients, data bags, and all data will be stored here on your provisioner machine if you do this.

You can use `with_chef_server` instead if you want to point at OSS, Hosted or Enterprise Chef, and if you don't specify a Chef server at all, it will use the one you are running chef-client against. Keep in mind when using `with_chef_server` and running `chef-client -z` on your workstation that you will also need to set the client name and signing key for the chef server. If you've already got knife.rb set up, then something like this will correctly create a client for the chef server on instance using your knife.rb configuration:

```ruby
with_chef_server "https://chef-server.example.org",
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]
```

**Note for Hosted/Enterprise Chef Servers**

Currently, you will need to add the 'clients' group to the 'admin' group in order for machine provisioning to work:

```
knife edit /groups/admin.json -e <editor>
```
Then add:
```
{
  "users": [
    "pivotal" # This is an internal superuser for Hosted/Enterprise Chef
  ],
  "groups": [
    "clients" # This is what you need to add
  ]
}
```

This can also be done through the Chef Server web UI (Administration tab > Groups > select admins Group > Add 'clients'


Kitchen
-------

Chef Provisioning also works with Test Kitchen, allowing you to test entire clusters, not just machines!  The repository for the kitchen-metal gem is https://github.com/doubt72/kitchen-metal.


Fixing conflict with chef-zero 3.2.1 and ~> 4.0 
-----------------------------------------------

If you run into the error `Unable to activate cheffish-1.0.0, because chef-zero-3.2.1 conflicts with chef-zero (~> 4.0)` you'll need to update the version of the chef gem included in the ChefDK.  Follow the instructions @ [https://github.com/fnichol/chefdk-update-app](https://github.com/fnichol/chefdk-update-app) and update chef to ~>12.2.1 

Bugs and The Plan
-----------------

Please submit bugs, gripes and feature requests at [https://github.com/chef/chef-provisioning/issues](https://github.com/chef/chef-provisioning/issues), contact John Keiser on Twitter at [@jkeiser2](https://twitter.com/jkeiser2), email at [jkeiser@chef.io](mailto:jkeiser@chef.io)

To contribute, just make a PR in the appropriate repo--also, make sure you've [signed the Chef Contributor License Agreement](https://supermarket.chef.io) (through your Chef Supermarket profile), since this is going into core Chef eventually. If you already signed this for a Chef contribution, you don't need to do so again--if you're not sure, you can check for your name [here](https://supermarket.chef.io/contributors) or if you signed up long ago check the [old list](https://github.com/chef/chef/blob/master/CLA_ARCHIVE.md)!
