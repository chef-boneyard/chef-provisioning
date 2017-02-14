# Configuring and using Provisioning drivers

Chef's `machine` resource has not changed, but the way you specify drivers has changed significantly. No longer are you encouraged to specify the driver name and credentials in the recipe (though it is still possible); instead, it is preferred to configure this information through Chef configuration files and the environment.

### Basic recipes

In a recipe, you use the `machine` and `machine_batch` resources to manipulate machines:

```ruby
machine 'webserver' do
  recipe 'apache'
end
```

You'll notice you don't specify where the machine should be or what OS it should have.  This configuration happens in the environment, configuration files or in recipes, described below.

(There are many things you can do with the `machine` resource, but we'll cover that in another post.)

## Drivers

To specify *where* the machine should be (AWS, Vagrant, etc.), you need a *driver*. We recommended using the drivers packaged in the latest version of the ChefDK.

#### Setting the driver with a driver URL

The driver you want is specified by URLs.  The first part of the URL, the scheme, identifies the Driver class that will be used.  The rest of the URL uniquely identifies the account or location the driver will work with.  Some examples of driver URLs:

- `fog:AWS:default`: connect to the AWS default profile (in `~/.aws/config`)
- `fog:AWS:123514512344`: connect to the AWS account # 123514512344
- `vagrant`: a vagrant directory located in the default location (`<configuration directory>/vms`)
- `vagrant:~/machinetest`: a vagrant directory at `~/machinetest`

There are a number of ways to set the driver URL.  For example:

- In a recipe using with_driver:
```ruby
with_driver 'fog:AWS:jkeiser' # the "jkeiser" profile from
machine 'web' do
  recipe 'apache'
end
machine 'db' do
  recipe 'mysql'
end
```
- In a recipe directly on the machine:
```ruby
machine 'web' do
  driver 'vagrant:~/machinetest' # Vagrantfiles in the given directory
  recipe 'apache'
end
machine 'db' do
  driver 'fog:AWS:default'
  recipe 'apache'
end
```
- In configuration (`knife.rb`):
```ruby
driver 'fog:AWS' # default profile
```
- In an environmental variable:
```
export CHEF_DRIVER=vagrant # stores things in <chef config dir>/vms
chef-client -z cluster.rb
```

Different machines may have different drivers.

### Canonical Driver URLs

There are many ways to specify a driver URL, but only one canonical. When we store a driver URL in a node, the URL is first canonicalized--turned into a unique, explicit form that can be used in multiple machines.

- For EC2, the form looks like `fog:AWS:726435164533:us-east-1', where 726435164533 is the AWS account ID (independent of profile) and us-east-1 is the region.
- For Vagrant, the form looks like `vagrant:/Users/jkeiser/machinetest`, with a fully-qualified directory name.

You can use these too, they just usually aren't as easy as the shorthands.

### Credentials configuration in Chef

Drivers usually need some credentials.  Rather than specify these in your recipe (bad mojo), these need to be specified outside:

- In the standard place for that driver (for example, `~/.aws/config` contains profiles with credentials and the AWS_* environment variables specify credentials):
```
export CHEF_DRIVER=fog:AWS:profilename
chef-client -z cluster.rb
```
- In Chef config (`knife.rb`):
```ruby
driver 'fog:AWS:123123124124:us-east-1'
driver_options :compute_options => { :aws_access_key_id => '...', :aws_secret_access_key => '...' }
```
- In a global Chef file for whenever you use that driver:
```ruby
drivers({
  'fog:AWS:myprofile' => {
    :driver_options => {
      :compute_options => {
        :aws_access_key_id => '...',
        :aws_secret_access_key => '...',
        :region => 'us-east-1'
      }
    }
  }
})
```
```
export CHEF_DRIVER=fog:AWS:123123124124
chef-client -z cluster.rb
```
- In a recipe:
```ruby
with_driver 'fog:AWS', :compute_options => { :aws_access_key_id => '...', :aws_secret_access_key => '...' }
```

There will be easier ways to specify this as Chef profiles and configuration evolve in the near future, as well.

## Machine options

### Provider specific options
See the driver specific Github page for an explanation of the supported options.

Machine options can be specified in Chef configuration or in recipes.  For example:

- In recipes with with_machine_options:
```ruby
with_driver 'vagrant'
with_machine_options :vagrant_options => { 'vm.box' => 'precise64' }
machine 'web' do
  recipe 'apache'
end
machine 'db' do
  recipe 'mysql'
end
```
- In recipes on machine definitions:
```ruby
with_driver 'vagrant' do
  machine 'web' do
    machine_options :vagrant_options => { 'vm.box' => 'centos6' }
    recipe 'apache'
  end
  machine 'db' do
    machine_options :vagrant_options => { 'vm.box' => 'precise64' }
    recipe 'mysql'
  end
end
```
- In Chef config (`knife.rb`):
```ruby
machine_options :vagrant_options => { 'vm.box' => 'centos6' }
```
- In Chef config associated with specific drivers:
```ruby
drivers({
  'vagrant:/Users/jkeiser/vms' => {
    :machine_options => {
      :vagrant_options => {
        'vm.box' => 'precise64'
      }
    }
  }
})
```

Machine options are *additive*.  If you specify `'vm.box' => 'precise64'` in Chef config, and then specify `'vm.ram' => '8G'` on the machine resource, the vagrant options for that will include *both* sets of option.

### Using Chef profiles (DEPRECATED)

It is not recommended to use the `CHEF_PROFILE` environment variable

### Private keys

chef-provisioning also helps you link up to your private keys.  The `private_key_paths` and `private_keys` Chef config variables let you tell Chef about sets of named private keys and paths where private keys can be found.

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
