# Writing Drivers

When you need to access a new PXE or cloud service, you need to write a new Driver. (For cloud services, often modifying chef-provisioning-fog will be sufficient rather than creating a whole new driver.)

## The Driver interface

The Driver interface is a set of 4 objects that allow provisioning programs to communicate with drivers.  There are several key objects in the Driver interface:

- `Driver`: Represents a "machine warehouse"--an AWS account, a set of vagrant machines, a PXE machine registry. You can ask it for new machines, power machines on and off, and get rid of machines you are no longer using.
- `Machine`: Represents a ready, connectable machine.  The machine interface lets you run commands, upload and download files, and converge recipes.  This is returned by Driver methods that create and connect to machines.
- `ManagedEntry`: Represents the saved information about a Machine.  Drivers use this to save information about how to locate and manipulate individual machines (like the AWS instance ID, PXE MAC address, or Vagrantfile location).
- `ActionHandler`: this is how Chef communicates back to the host provisioning program (like the machine resource, test-kitchen, or knife command line). It primarily uses it to report actions it performs and progress, so that the host can print pretty output informing the user.

## Picking a URL scheme

Every driver instance must be identified uniquely by a URL.  This generally describes *where* the list of servers lives.  For cloud providers this will generally be an account or a server. For VMs and containers it will either be a directory or global to the machine.

Example URLs from real drivers:

```
fog:AWS:1231241212          # account ID (canonical)
fog:AWS:myprofile           # profile in ~/.aws/config
fog:AWS                     # implies default profile
vagrant:/Users/jkeiser/vms  # path to vagrant vm (canonical)
vagrant:~/vms               # path to vagrant vm (non-canonical)
vagrant                     # implies <chef config dir>/vms
```

The bit before the colon--the scheme--is the identifier for your driver gem.
Some of these URLs are canonical and some are not.  When you create a driver with one of these URLs, the driver_url on the resulting driver *must* be the canonical URL.  For example, Chef::Provisioning.driver_for_url("fog:AWS").driver_url would equal "fog:AWS:12312412312" (or whatever your account is).  This is important because the canonical URL will be stored in the URL and may be used by different people on different workstations with different profile names.

## from_url

To instantiate the driver, you must implement Driver.from_url.  This method's job is to canonicalize the URL, and to make an instance of the Driver.  For example:

```ruby
require 'chef/provisioning/driver'

class MyDriver < Chef::Provisioning::Driver
  def self.from_url(url, config)
    MyDriver.new(url, config)
  end

  def initialize(url, config)
    super(url, config)
  end

  def cloud_url
    scheme, cloud_url = url.split(':', 2)
    cloud_url
  end

  def the_ultimate_cloud
    TheUltimateCloud.connect(cloud_url, driver_config['username'], driver_config['password'])
  end
end
```

## driver_config and credentials

As you can see in the previous example, driver_config is where credential information is passed to your driver. It ultimately comes from config[:driver_config] passed to the from_url method. For example, our hypothetical driver could allow the user to specify this in their Chef config:

```ruby
driver 'mydriver:http://the_ultimate_server.com:8080'
driver_options :username => 'me', :password => 'mypassword'
```

This is the standard place for users to put credentials.  It is a freeform hash, so you should document what keys you expect users to put there to help you connect.

Please feel free to work with any files or environment variables that drivers typically support (like `~/.aws/config`), so that you can share configuration with standard tools for that cloud/VM/whatever.

## allocate_machine

Allocate machine is the first method called when creating a machine.  Its job is to reserve the machine, and to return quickly.  It may start the machine spinning up in the background, but it should not block waiting for that to happen.

allocate_machine takes an action_handler, machine_spec, and a machine_options argument.  action_handler is where the method should report any changes it makes.  machine_spec.reference will contain the current known machine information, loaded from persistent storage (like from the node).  machine_options contains the desired options for creating the machine.  Both machine_spec.reference and machine_options are freeform hashes owned by the driver.  You should document what options the user can pass in your driver's documentation.

Note: `machine_spec.reference` *must* contain a `driver_url` key with the canonical driver URL in it, so that Chef can tell where the machine came from.

By the time the method is finished, the machine should be reserved and its information stored in machine_spec.reference.  If it is not feasible to do this quickly, then it is acceptable to defer this to ready_machine.

```ruby
  def allocate_machine(action_handler, machine_spec, machine_options)
    if machine_spec.reference
      if !the_ultimate_cloud.server_exists?(machine_spec.reference['server_id'])
        # It doesn't really exist
        action_handler.perform_action "Machine #{machine_spec.reference['server_id']} does not really exist.  Recreating ..." do
          machine_spec.reference = nil
        end
      end
    end
    if !machine_spec.reference
      action_handler.perform_action "Creating server #{machine_spec.name} with options #{machine_options}" do
        private_key = get_private_key('bootstrapkey')
        server_id = the_ultimate_cloud.create_server(machine_spec.name, machine_options, :bootstrap_ssh_key => private_key)
        machine_spec.reference = {
          'driver_url' => driver_url,
          'driver_version' => MyDriver::VERSION,
          'server_id' => server_id,
          'bootstrap_key' => 'bootstrapkey'
        }
      end
    end
  end
```

In all methods, you should wrap any substantive changes in `action_handler.perform_action`.  Progress can be reported with `action_handler.report_progress`.  NOTE: action_handler.perform_action will not actually execute the block if the user passed `--why-run` to chef-client.  Why Run mode is intended to simulate the actions it would perform, but not actually perform them.

If you notice the user wants the machine to be *different* than it is now--for example, to have more RAM or disk or processing power--you should either safely move the data over to a new instance, or warn the user that you cannot fulfill their desire.

### Working with private keys

You'll notice the service is passed a private key for bootstrap.  This is the bootstrap key, and in our example, TheUltimateCloud will allow you to ssh to the machine with the root user using that private key after it is bootstrapped.  (Several cloud services already work this way.)

The issue one has here is, the user needs to be able to pass you these keys.  chef-provisioning introduces configuration variables `:private_keys` and `:private_key_paths` to allow the user to tell us about his keys.  We then refer to the keys by name (rather than path) in drivers, and look them up from configuration.

You can call the `get_private_key(name)` method from the Driver base class to get a private key by name.

## ready_machine

ready_machine is the other half of the machine creation story. This method will do what it needs to bring the machine up. When the method finishes, the machine must be warm and connectable.  ready_machine returns a Machine object.  An example:

```ruby
  def ready_machine(action_handler, machine_spec, machine_options)
    server_id = machine_spec.reference['server_id']
    if the_ultimate_cloud.machine_status(server_id) == 'stopped'
      action_handler.perform_action "Powering up machine #{server_id}" do
        the_ultimate_cloud.power_on(server_id)
      end
    end

    if the_ultimate_cloud.machine_status(server_id) != 'ready'
      action_handler.perform_action "wait for machine #{server_id}" do
        the_ultimate_cloud.wait_for_machine_to_have_status(server_id, 'ready')
      end
    end

    # Return the Machine object
    machine_for(machine_spec, machine_options)
  end
```

ready_machine takes the same arguments as allocate_machine, and machine_spec.reference will contain any information that was placed in allocate_machine.

### Creating the Machine object

The Machine object contains a lot of the complexity of connecting to and configuring a machine once it is ready.  Happily, most of the work is already done for you here.

```ruby
require 'chef/provisioning/transport/ssh_transport'
require 'chef/provisioning/convergence_strategy/install_cached'
require 'chef/provisioning/machine/unix_machine'

  def machine_for(machine_spec, machine_options)
    server_id = machine_spec.reference['server_id']
    hostname = the_ultimate_cloud.get_hostname()
    username = the_ultimate_cloud.get_user()
    ssh_options = {
      :auth_methods => ['publickey'],
      :keys => [ get_key('bootstrapkey') ],
    }
    transport = Chef::Provisioning::Transport::SSH.new(the_ultimate_cloud.get_hostname(server_id), username, ssh_options, {}, config)
    convergence_strategy = Chef::Provisioning::ConvergenceStrategy::InstallCached.new(machine_options[:convergence_options], {})
    Chef::Provisioning::Machine::UnixMachine.new(machine_spec, transport, convergence_strategy)
  end
```

WindowsMachine and WinRMTransport are also available for Windows machines.  You can look at how these are instantiated in the chef-provisioning-vagrant driver.

## destroy_machine

The destroy_machine function is fairly straightforward:

```ruby
  def destroy_machine(action_handler, machine_spec, machine_options)
    if machine_spec.reference
      server_id = machine_spec.reference['server_id']
      action_handler.perform_action "Destroy machine #{server_id}" do
        the_ultimate_cloud.destroy_machine(server_id)
        machine_spec.reference = nil
      end
    end
  end
```

## stop_machine

Same with stop_machine:

```ruby
  def stop_machine(action_handler, machine_spec, machine_options)
    if machine_spec.reference
      server_id = machine_spec.reference['server_id']
      action_handler.perform_action "Power off machine #{server_id}" do
        the_ultimate_cloud.power_off(server_id)
      end
    end
  end
```

## connect_to_machine

This method should return the Machine object for a machine, *without* spinning it up.  Because of how we coded `ready_machine`, we can just do this:

```ruby
  def connect_to_machine(machine_spec, machine_options)
    machine_for(machine_spec, machine_options)
  end
```

## Creating the init file

Drivers are automatically loaded based on their driver URL.  The way Chef does this is by extracting the *scheme* from the URL, and then doing `require 'chef/provisioning/driver_init/schemename'`. So for our driver to load when driver is set to `mydriver:http://theultimatecloud.com:80`, we need to create a file named chef/provisioning/driver_init/mydriver.rb` that looks like this:

```ruby
require 'chef/provisioning_mydriver/mydriver'
Chef::Provisioning.register_driver_class("mydriver", Chef::ProvisioningMyDriver::MyDriver)
```

After this require, chef-provisioning will call `Chef::ProvisioningMyDriver::MyDriver.from_url('mydriver:http://theultimatecloud.com:80', config)` and will have a driver!

## Publishing it all as a gem

For users to actually use their gem, you need to release the gem on rubygems.org, and people will do `gem install chef-provisioning-mydriver`.  Instructions for publishing a gem are at rubygems [here](http://guides.rubygems.org/publishing/).

## Parallelism! (`allocate_machines`)

By default Chef Provisioning provides parallelism on top of your driver by calling allocate_machine and ready_machine in parallel threads.  But many providers have interfaces that let you spin up many machines at once.  If you have one of these, you can implement the `allocate_machines` method.  It takes the action_handler you love and know, plus a specs_and_options hash (keys are machine_spec and values are machine_options), and a parallelizer object you can optionally use to run multiple ruby blocks in parallel.

```ruby
  def allocate_machines(action_handler, specs_and_options, parallelizer)
    private_key = get_private_key('bootstrapkey')
    servers = []
    server_names = []
    specs_and_options.each do |machine_spec, machine_options|
      if !machine_spec.reference
        servers << [ machine_spec.name, machine_options, :bootstrap_ssh_key => private_key]
        server_names << machine_spec.name
      end
    end

    # Tell the cloud API to spin them all up at once
    action_handler.perform_action "Allocating servers #{server_names.join(',')} from the cloud" do
      the_ultimate_cloud.create_servers(servers)
    end
  end
```

You can also implement ready_machines, destroy_machines and stop_machines.
