# Configuring and using Metal drivers

Metal's `machine` resource has not changed, but the way you specify drivers has changed significantly. No longer are you encouraged to specify the driver name and credentials in the recipe (though it is still possible); instead, it is preferred to configure this information through Chef configuration files and the environment.

### Basic recipes

In a recipe, you use the `machine` and `machine_batch` resources to manipulate machines:

```ruby
machine 'webserver' do
  recipe 'apache'
end
```

You'll notice you don't specify where the machine should be or what OS it should have.  This configuration happens in the environment, configuration files or in recipes, described below.

(There are many things you can do with the `machine` resource, but we'll cover that in another post.)

## Installing drivers

chef-metal drivers are generally named chef-metal-<drivername>.  To install, just use `gem install chef-metal-docker` (for instance).  Fog and Vagrant come pre-installed when you install chef-metal.

## Using a driver

To specify *where* the machine should be (AWS, Vagrant, etc.), you need a *driver*. There are several drivers out there, including:

- Fog (which connects with AWS EC2, OpenStack, DigitalOcean and SoftLayer)
- VMware VSphere
- Vagrant (VirtualBox and VMware Fusion)
- LXC
- Docker
- Raw SSH (with a list of already-provisioned servers)

(Note: as of this writing, only Fog and Vagrant are up to date with the new Driver interface, but that will change very quickly.)

#### Setting the driver with a driver URL

The driver you want is specified by URLs.  The first part of the URL, the scheme, identifies the Driver class that will be used.  The rest of the URL uniquely identifies the account or location the driver will work with.  Some examples of driver URLs:

- `fog:AWS:default`: connect to the AWS default profile (in `~/.aws/config`)
- `fog:AWS:123514512344`: connect to the AWS account # 123514512344
- `vagrant`: a vagrant directory located in the default location (`<configuration directory>/vms`)
- `vagrant:~/machinetest`: a vagrant directory at `~/machinetest`

To set the driver that will be used by default, you can place the following in your Chef or Knife config (such as `.chef/knife.rb`):

```ruby
local_mode true
log_level :debug
driver 'vagrant:~/machinetest'
```

You can also set the `CHEF_DRIVER` environment variable:

```
CHEF_DRIVER=fog:AWS:default chef-client -z my_cluster.rb
```

### Driver options (credentials)

Driver options contain the credentials and necessary information to connect to the driver.

To specify driver_options, you can put this in knife.rb:

```ruby
# In knife.rb
driver 'fog:AWS:default'
driver_options {
  :aws_profile => 'jkeiser_work'
}
```

If you alternate between many drivers, you can also set options that are "glued" to a specific driver by putting this in your Chef config:

```ruby
# In knife.rb
drivers {
  'fog:AWS:123445315112' => {
    :driver_options => {
      aws_profile => 'jkeiser_work'
    }
  }
}
```

As you can see, machine_options can be specified as well.  We'll talk about those more later.

There will be easier ways to specify this as Chef profiles and configuration evolve in the near future, as well.

## Machine options

Machine options can be specified in Chef configuration or in recipes.  In Chef config, it looks like this:

```ruby
# In knife.rb
driver 'vagrant'
# This will apply to all machines that don't override it
machine_options :vagrant_options => {
  :bootstrap_options => {
    'vm.box' => 'precise64'
  }
}
```

And with the `with_machine_options` directive to affect multiple machines:

```ruby
# In recipe
with_driver 'vagrant'

with_machine_options :vagrant_options => {
  'vm.box' => 'precise64'
}

machine 'webserver' do
  recipe 'apache'
end
machine 'database' do
  recipe 'mysql'
end
```

Or directly on the machines:

```ruby
# In recipe
machine 'webserver' do
  driver 'vagrant:'
  machine_options :vagrant_options => {
    'vm.box' => 'precise64'
  }
  recipe 'apache'
end
```

This sort of mixing of physical and logical location is often not advisable, but there are situations where it's expedient or even required, so it's supported.

NOTE: with_machine_options can also take a do block that will apply to all machines inside it.

As before, you can even attach options to specific drivers (defaults for specific drivers and accounts can be useful):

```ruby
# In knife.rb
drivers {
  'fog:AWS:123445315112' => {
    :driver_options => {
      aws_profile => 'jkeiser_work'
    }
    :machine_options => {
      :bootstrap_options => {
        :region => 'us-east-1'
      }
    }
  },
  'vagrant:/Users/jkeiser/vms' => {
    :machine_options => {
      :vagrant_options => {
        'vm.box' => 'precise64'
      }
    }
  }
}
```

### Using Chef profiles

You can set the `CHEF_PROFILE` environment variable to identify the profile you want to load.

In Chef config:

```ruby
# In knife.rb
profiles {
  'default' => {
  }
  'dev' => {
    :driver => 'vagrant:',
    :machine_options => {
      :vagrant_options => {
        'vm.box' => 'precise64'
      }
    }
  },
  'test' => {
    :driver => 'fog:AWS:test',
    :machine_options => {
      :bootstrap_options => {
        :flavor_id => 'm1.small'
      }
    }
  },
  'staging' => {
    :driver => 'fog:AWS:staging',
    :driver_options => {
      :bootstrap_options => {
        :flavor_id => 'm1.small'
      }
    }
  }
}
```

This will get better tooling and more integrated Chef support in the future, but it is a good start.  You can set the current profile using the `CHEF_PROFILE` environment variable:

```
CHEF_PROFILE=dev chef-client -z my_cluster.rb
```
