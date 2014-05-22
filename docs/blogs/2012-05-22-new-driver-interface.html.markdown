# Chef Metal, Configuration and Drivers

As Chef Metal approaches 1.0, we've landed a huge configuration and driver interface improvement intended to enable:

- A standard way to specify credentials and keys that keeps them out of recipes and allows them to be used in multiple places
- External commands (like "metal execute") that can look up information and manage a node independent of the original Metal recipe
- Environmental and directory-specific configuration
- Make the drivers easily usable in test-kitchen and knife

How you create machines has not changed from a *logical* standpoint, but from a *physical* standpoint--how you configure, build and use drivers--it has changed significantly and for the better!

I'll talk a little bit about the user-level changes here, but you can read about these changes in depth in the docs/ section of the chef-metal repository:

- [Configuring and using drivers](https://github.com/opscode/chef-metal/blob/master/docs/configuration.md#configuring-and-using-metal-drivers)
- [Building drivers](https://github.com/opscode/chef-metal/blob/master/docs/building_drivers.md#writing-drivers)
- [Using drivers in your own programs](https://github.com/opscode/chef-metal/blob/master/docs/embedding.md)

## Using Metal today

We've simplified the use of metal, in such a way that configuration is now shared.  Here is a very simple use of Metal.

- Install chef-metal:
  ```
  gem install chef-metal
  ```
- Put your AWS credentials in `~/.aws/config` a la [http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#d0e726](this tutorial)
  ```

  ```
- Make a simple recipe that creates two machines:
  ```
  require 'chef_metal'
  machine 'web'
  machine 'db'
  ```
- Run the chef-client:
  ```
  export CHEF_DRIVER=fog:AWS
  chef-client -z blah.rb
  ```

Wallah!  Two EC2 machines!

## The Metal command line

The other major takeaway from this release is that it enables external command line.  Let's use the demo (probably not final) metal command line to destroy the instances we just created:

```
metal destroy db web
```

## Driver URLs

Drivers are uniquely identifiable by their URL.  A driver URL consists of a scheme and then driver-specific stuff. You can specify driver URL several ways:

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

- For EC2, the form looks like `fog:AWS:726435164533', where 726435164533 is the AWS account ID (independent of profile).
- For Vagrant, the form looks like `vagrant:/Users/jkeiser/machinetest`, with a fully-qualified directory name.

You can use these too, they just usually aren't as easy as the shorthands.

### Credentials configuration in Chef

Drivers usually need some credentials.  Rather than specify these in your recipe (bad mojo), these need to be specified outside:

- In Chef config (`knife.rb`):
  ```ruby
  driver 'fog:AWS:123123124124'
  driver_options :aws_access_key_id => '...', :aws_secret_access_key => '...'
  ```
- In a global Chef file for whenever you use that driver:
  ```ruby
  drivers {
    'fog:AWS:123123124124' => {
      :driver_options => {
        :aws_access_key_id => '...',
        :aws_secret_access_key => '...'
      }
    }
  }
  ```
  ```
  export CHEF_DRIVER=fog:AWS:123123124124
  chef-client -z cluster.rb
  ```

## Machine options

Absolutely everything that is not credentials should be specified in machine_options.  machine_options can be added in several places:

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
  drivers {
    'vagrant:/Users/jkeiser/vms' => {
      :machine_options => {
        :vagrant_options => {
          'vm.box' => 'precise64'
        }
      }
    }
  }
  ```

Machine options are *additive*.  If you specify `'vm.box' => 'precise64'` in Chef config, and then specify `'vm.ram' => '8G'` on the machine resource, the vagrant options for that will include *both* sets of option.

### Private keys

chef-metal also helps you link up Metal to your private keys.  The `private_key_paths` and `private_keys` Chef config variables let you tell Metal about sets of named private keys and paths where private keys can be found.

By default, chef-metal will search for a private key named 'blah' in <config dir>/keys/blah, or ~/.ssh/blah.

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

This is very very early days for profiles, and in the future I expect we will allow them to be automatically loaded from their own files, and easier to configure, in the future.  Perhaps even have more sophisticated things like automatic key paths, caches and such specific to a given profile.  But the potential is there to be a very useful way to use both Chef and Chef Metal.
