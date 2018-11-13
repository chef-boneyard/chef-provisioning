Chef Provisioning
==========
[![Status](https://travis-ci.org/chef/chef-provisioning.svg?branch=master)](https://travis-ci.org/chef/chef-provisioning)
[![Gem Version](https://badge.fury.io/rb/chef-provisioning.svg)](http://badge.fury.io/rb/chef-provisioning)

Please join us in Slack by signing up at http://community-slack.chef.io/ and joining `#chef-provisioning`

Overview
==========

Chef Provisioning is a Cookbook and Recipe based approach for managing your infrastructure. Users can codify their infrastructure and use Chef to converge their infrastructure to the desired state. It has a plugin model (called Drivers) to manage different infrastructures, including AWS, Azure and Fog.

Chef Provisioning is maintained according to the [Chef Maintenance Policy](https://github.com/chef/chef-rfc/blob/master/rfc030-maintenance-policy.md).

Drivers
-------------

Due to the age and engagement level with different Drivers they have fallen into two categories - maintained and unmaintained.

Maintained drivers have a representative in the maintenance policy and get triaged / discussed during office hours. They are

| [AWS](https://github.com/chef/chef-provisioning-aws) | [Fog](https://github.com/chef/chef-provisioning-fog) |
| ---- | ---- |
| [![Gem Version](https://badge.fury.io/rb/chef-provisioning-aws.svg)](http://badge.fury.io/rb/chef-provisioning-aws) | [![Gem Version](https://badge.fury.io/rb/chef-provisioning-fog.svg)](http://badge.fury.io/rb/chef-provisioning-fog) |

Maintained by Chef-Partners:

* [vSphere](https://github.com/chef-partners/chef-provisioning-vsphere)
* [vra](https://github.com/chef-partners/chef-provisioning-vra)

Maintained, not by Chef:

* [AzureRM](https://github.com/pendrica/chef-provisioning-azurerm)

Unmaintained Drivers are at risk of becoming stale. They are:

* [Docker](https://github.com/chef/chef-provisioning-docker)
* [ssh](https://github.com/chef/chef-provisioning-ssh)
* [Vagrant](https://github.com/chef/chef-provisioning-vagrant)
* [LXC](https://github.com/chef/chef-provisioning-lxc)
* [Hanlon](https://github.com/chef/chef-provisioning-hanlon)

Target Audience
-------------

Chef Provisioning is a good fit for people who use or want to use the Chef ecosystem to manage their infrastructure. Infrastructure is represented as Chef Resources and managed in Chef Recipes and Cookbooks. These recipes run on a provisioner node and attempt to converge the infrastructure idempotently. The AWS driver is the most used, the most tested and receives the most updates.

Chef Provisioning and its Drivers are maintained by the open source community. They currently have a slow tempo for issue triage and pull request merging. Troubleshooting a bug may require stepping through the Ruby Chef codebase and engaging the community.

If you are new to Chef and Chef Provisioning, learning both can be daunting. If you are not familiar with Ruby as well, double the learning curve. Successful provisioning users know how they want to manage their cookbooks. Generally this is some CI/CD pipeline.

Chef is very flexible which allows customized provisioning solutions at the cost of high complexity. This makes it hard to document all the possible use cases. Patterns (for example, how to manage the provisioning node and run the provisioning recipes) are not well documented.

Chef Provisioning should be used to manage infrastructure (CRUD operations) and register Chef nodes with the server for the first time only. Other use cases (like scheduling chef runs, node inventory or reporting) are not supported.

Documentation
-------------

These are the primary documents to help learn about using Provisioning and creating Provisioning drivers:

* [Chef Docs](https://docs.chef.io/provisioning.html)
* [Frequently Asked Questions](https://github.com/chef/chef-provisioning/blob/master/docs/faq.md)
* [Configuration](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#configuring-and-using-provisioning-drivers)
* [Writing Drivers](https://github.com/chef/chef-provisioning/blob/master/docs/building_drivers.md#writing-drivers)
* [Embedding](https://github.com/chef/chef-provisioning/blob/master/docs/embedding.md)

Media
-----
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

Try It Out
----------

You can try out Chef Provisioning in many different flavors.

### Vagrant

To give it a spin, install the latest ChefDK, Vagrant and VirtualBox. Run the following from the `chef-provisioning/docs/examples` directory:

```
export CHEF_DRIVER=vagrant
export VAGRANT_DEFAULT_PROVIDER=virtualbox
chef-client -z vagrant_linux.rb simple.rb
```

This will create two vagrant precise64 linux boxes, "mario" and "luigi1", in `~/machinetest`, bootstrapped to an empty runlist.  For Windows, you can replace `myapp::linux` with `myapp::windows`, but you'll need your own Windows vagrant box to do that (licensing!).

### AWS

If you have an AWS account, you can spin up a machine there like this:

```
export CHEF_DRIVER=aws
chef-client -z simple.rb
```

This will create two linux boxes in the AWS account referenced by your default profile in `~/.aws/config` (or your environment variables).

### DigitalOcean

If you are on DigitalOcean and using the `tugboat` gem, you can do this:

```
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

### Machine options

You can pass machine options that will be used by `machine`, `machine_batch` and `machine_image` to
configure the machine:

```ruby
with_machine_options({
  convergence_options: {
    chef_version: "12.4.1",
    prerelease: false,
    chef_client_timeout: 120*60, # Default: 2 hours
    chef_config: { :log_level => :debug }, # Hash containing additional options to inject into client.rb, or String containing additional text to inject into client.rb
    chef_server: "http://my.chef.server/", # TODO could conflict with https://github.com/chef/chef-provisioning#pointing-boxes-at-chef-servers
    bootstrap_proxy: "http://localhost:1234",
    bootstrap_no_proxy: "localhost, *.example.com, my.chef.server",
    rubygems_url: "http://mirror.example.org",
    ssl_verify_mode: :verify_peer,
    client_rb_path: "/etc/chef/client.rb", # <- DEFAULT, overwrite if necessary
    client_pem_path: "/etc/chef/client.pem", # <- DEFAULT, overwrite if necessary
    allow_overwrite_keys: false, # If there is an existing client.pem this needs to be true to overwrite it
    private_key_options: {}, # TODO ????? Something to do with creating node object
    source_key: "", # ?????
    source_key_pass_phrase: "", # ?????
    source_key_path: "", # ?????
    public_key_path: "", # ?????
    public_key_format: "", # ?????
    admin: "", # ?????
    validator: "", # ?????
    ohai_hints: { :ec2 => { :key => :value } }, # Map from hint file name to file contents, this would create /etc/chef/ohai/hints/ec2.json,
    ignore_failure: [1, 5..10, SomeSpecificError], # If true don't let a convergence failure on provisioned machine stop the provisioning workstation converge.  Can also provide a single exit code to ignore (no array) or `true` to ignore all RuntimeErrors
    # The following are only available for Linux machines
    install_sh_url: "https://www.chef.io/chef/install.sh", # <- DEFAULT, overwrite if necessary
    install_sh_path: "/tmp/chef-install.sh", # <- DEFAULT, overwrite if necessary
    install_sh_arguments: "-P chefdk", # Additional commands to pass to install.sh
    # The following are only available for Windows machines
    install_msi_url: "foo://bar.com"
  },
  ssh_username: "ubuntu", # Username to use for ssh and WinRM
  ssh_gateway: "user@gateway", # SSH gateway configuration
  ssh_options: { # a list of options to Net::SSH.start
    :auth_methods => [ 'publickey' ], # DEFAULT
    :keys_only => true, # DEFAULT
    :host_key_alias => "#{instance.id}.AWS", # DEFAULT
    :key_data => nil, # use key from ssh-agent instead of a local file; remember to ssh-add your keys!
    :forward_agent => true, # you may want your ssh-agent to be available on your provisioned machines
    :never_forward_localhost => false, # This will, if set, disable SSH forwarding if it does not work/make sense in your envirnoment
    :remote_forwards => [
        # Give remote host access to squid proxy on provisioning node
        {:remote_port => 3128, :local_host => 'localhost', :local_port => 3128,},
        # Give remote host access to private git server
        {:remote_port => 2222, :local_host => 'git.example.com', :local_port => 22,},
    ],
    # You can send net-ssh log info to the Chef::Log if you are having
    # trouble with ssh.
    :logger => Chef::Log,
    # If you use :logger => Chef::Log and :verbose then your :verbose setting
    # will override the global Chef::Config. Probably don't want to do this:
    #:verbose => :warn,
  }
})
```

This options hash can be supplied to either `with_machine_options` or directly into the `machine_options`
attribute.

Individual drivers will often add their own driver specific config.  For example, AWS expects a `:bootstrap_options` hash at the same level as `:convergence_options`.

### Anatomy of a Recipe

The ChefDK comes with a provisioner for Vagrant, an abstraction that covers VirtualBox, VMware and other Virtual Machine drivers. In docs/examples, you can run this to try it:

```ruby
export CHEF_DRIVER=vagrant
export VAGRANT_DEFAULT_PROVIDER=virtualbox
chef-client -z vagrant_linux.rb simple.rb
```

To use with VMware, simply update the prior example to read ```export VAGRANT_DEFAULT_PROVIDER=vmware_fusion```

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

### Pointing Boxes at Chef Servers

By default, Chef Provisioning will put your boxes on the same Chef server you started chef-client with (in the case of -z, that's a local chef-zero server). Sometimes you want to put your boxes on different servers.  There are a couple of ways to do that:

```ruby
with_chef_local_server :chef_repo_path => '~/repo'
```

`with_chef_local_server` is a generic directive that creates a chef-zero server pointed at the given repository.  nodes, clients, data bags, and all data will be stored here on your provisioner machine if you do this.

You can use `with_chef_server` instead if you want to point at OSS, Hosted or Enterprise Chef, and if you don't specify a Chef server at all, it will use the one you are running chef-client against. Keep in mind when using `with_chef_server` and running `chef-client -z` on your workstation that you will also need to set the client name and signing key for the chef server. If you've already got knife.rb set up, then something like this in the provisioning recipe will correctly create a client for the chef server on instance using your knife.rb configuration:

```ruby
with_chef_server "https://chef-server.example.org",
:options =>{  
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]
  }
```

Finally, you can specify a Chef Server for an individual machine by using the `chef_server` attribute.  This attribute takes the same additional options (`:client_name`, `:signing_key_filename`) that `with_chef_server` does.

```ruby
machine 'mario' do
  chef_server :chef_server_url => "https://chef-server.example.org"
end
```

### Configuring ACLs

If you want to run your provisionning recipes from an actual chef node, rather than from your workstation, you need to give that node's client enough rights to create the node and client he'll be provisioning on the chef server. Without those additional rights, the provisioning will fail with a error along the lines of `chef_client[mymachine] had an error: Net::HTTPServerException: 403 "Forbidden"`.

A clean solution to this problem is to use [knife-acl](https://github.com/chef/knife-acl) to define a `provisioners` group with the required rights, and add your client to it:

```shellsession
$> chef gem install knife-acl
$> knife group create provisioners
$> knife acl add group provisioners containers clients read,create,update,delete,grant
$> knife acl add group provisioners containers nodes read,create,update,delete,grant
$> knife group add client my_provisioning_client_name provisioners
```

Bugs and The Plan
-----------------

Please submit bugs, gripes and feature requests at [https://github.com/chef/chef-provisioning/issues](https://github.com/chef/chef-provisioning/issues) and join us in the Slack room to chat.

To contribute, just make a PR in the appropriate repo following the Chef [contribution process](https://github.com/chef/chef/blob/master/CONTRIBUTING.md#contribution-process).
