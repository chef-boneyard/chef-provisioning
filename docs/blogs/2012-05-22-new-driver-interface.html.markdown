# Chef Metal 0.11, Configuration and Drivers

Chef Metal has gotten a facelift!  We've tried to keep the interface stable for a long time as we find out what works and what doesn't, and now we're ready to make some changes.  In 0.11, we've landed a huge configuration and driver interface improvement intended to enable:

- A standard way to specify credentials and keys that keeps them out of recipes and allows them to be used in multiple places (Chef config)
- A cohesive way to refer to an environment (Chef profiles)
- Make the drivers easily usable in external programs like test-kitchen and knife to create and manage machines (Driver interface)

How you create machines has not changed from a *logical* standpoint, but from a *physical* standpoint--how you configure, build and use drivers--it has changed significantly and for the better!

I'll talk a little bit about the user-level changes here, but you can read about these changes in depth in the docs/ section of the chef-provisioning repository:

- [Configuring and using drivers](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#configuring-and-using-metal-drivers)
- [Building drivers](https://github.com/chef/chef-provisioning/blob/master/docs/building_drivers.md#writing-drivers)
- [Using drivers in your own programs](https://github.com/chef/chef-provisioning/blob/master/docs/embedding.md)

I'll give an example of how to use chef-provisioning in Vagrant.  Many other clouds are supported.

## Using Metal today: AWS

- Install chef-provisioning:
```ruby
gem install chef-provisioning
```
- Put your AWS credentials in `~/.aws/config` a la [http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#d0e726](this tutorial).  It should look like this:
```
[default]
aws_access_key_id=...
aws_secret_access_key=...
```
- Make a simple recipe that creates two machines:
```
require 'chef/provisioning'
machine 'web'
machine 'db'
```
- Run the chef-client:
```
export CHEF_DRIVER=fog:AWS
chef-client -z blah.rb
```

Wallah!  Two EC2 machines, in parallel!

## Drivers, credentials and machine options

Drivers are now identifiable entirely by a URL (like `fog:AWS:default` or `vagrant:~/vms`).  To choose a driver, you specify its URL and the driver will be automatically loaded.  URLs have a flexible format, and vary for what makes sense for each driver.  Examples of setting driver URLs are [here.](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#setting-the-driver-with-a-driver-url)

Credentials for drivers can be specified, and Chef Metal makes it easy to specify these while keeping them out of your recipes (or anything likely to be checked in to source control!).  There are many ways to specify them--see the [documentation](https://github.com/chef/chef-provisioning/blob/master/docs/configuration.md#credentials-configuration-in-chef) for examples.

Absolutely everything that is not credentials should be specified in machine_options.  These are how you specify the OS you want to lay down, the keys you want to use to access the machine remotely, mount points, and everything else.  machine_options are generally specified in recipes, but may also be specified in configuration; details are [here]().

## Private keys

chef-provisioning also helps you link up Metal to your private keys.  The `private_key_paths` and `private_keys` Chef config variables let you tell Metal about sets of named private keys and paths where private keys can be found.

By default, chef-provisioning will search for a private key named 'blah' in <config dir>/keys/blah, or ~/.ssh/blah.

This manifests, for example, when you bootstrap AWS servers:

```ruby
driver 'fog:AWS'
with_machine_options :bootstrap_options => { :key_name => 'blah' }
machine 'my_machine' do
  recipe 'users'
end
```

In this example, mybootstrapkey should be located in ~/.chef/keys or in `~/.ssh`.

All private key resources, including `private_key` and `fog_key_pair`, will default to placing keys in this location so that they can be easily retrieved later.

## Chef profiles

This release also has nascent support for Chef profiles, which don't exist in Chef yet.  To use them, you can set an environment variable called CHEF_PROFILE or set `profile 'name'` in your `knife.rb`, Chef Metal will load profile information here.  This can be super useful to give shorthand for different environments:

```ruby
profiles {
  'dev' => {
    :driver => 'vagrant',
    :local_mode => true
  },
  'test' => {
    :driver => 'fog:AWS',
    :local_mode => true
  },
  'prod' => {
    :driver => 'fog:AWS:1324123412',
    :aws_access_key_id => '...',
    :aws_secret_access_key => '...',
    :chef_server_url => 'https://api.opscode.com/organizations/my_prod_org',
    :node_name => 'jkeiser',
    :client_key => '~/.chef/keys/jkeiser.pem'
  }
}
```

You can specify the profile with the CHEF_PROFILE environment variable or the `profile` configuration variable in your Chef configuration file.

This is very very early days for profiles, and in the future I expect we will allow them to be automatically loaded from their own files, and easier to configure, in the future.  Perhaps even have more sophisticated things like automatic key paths, caches and such specific to a given profile.  But the potential is there to be a very useful way to use both Chef and Chef Metal.
