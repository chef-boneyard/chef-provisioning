## Using Metal drivers directly in your programs

There are many programs that could benefit from creating and manipulating machines with Metal.  For example, the `machine` and `machine_batch` resources in Chef recipes, `test-kitchen`, and `knife` all use the Metal Driver interface for provisioning.  This is an explanation of how the Driver interface is used.

### Configuration

The fundamental bit of Metal is the configuration, passed in to.  This is a hash, with symbol keys for the important top level things:

```ruby
{
  :driver => 'fog:AWS:default',
  :driver_options => { <credentials here, if you must> },
  :machine_options => { <options here> }
  :chef_server_url => 'https://api.opscode.com/organizations/myorg'
  :node_name => 'jkeiser', # Client or username to connect to Chef server
  :client_key => '/Users/jkeiser/.chef/keys/jkeiser.pem'
}
```

#### Getting the Chef config

To get the Chef config, you can use this code:

```ruby
require 'chef/config'
require 'chef/knife'
require 'chef/config_fetcher'
require 'cheffish'

chef_config = begin
  Chef::Config.config_file = Chef::Knife.locate_config_file
  config_fetcher = Chef::ConfigFetcher.new(Chef::Config.config_file, Chef::Config.config_file_jail)
  if Chef::Config.config_file.nil?
    Chef::Log.warn("No config file found or specified on command line, using command line options.")
  elsif config_fetcher.config_missing?
    Chef::Log.warn("Did not find config file: #{Chef::Config.config_file}, using command line options.")
  else
    config_content = config_fetcher.read_config
    config_file_path = Chef::Config.config_file
    begin
      Chef::Config.from_string(config_content, config_file_path)
    rescue Exception => error
      Chef::Log.fatal("Configuration error #{error.class}: #{error.message}")
      filtered_trace = error.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each {|line| Chef::Log.fatal("  " + line )}
      Chef::Application.fatal!("Aborting due to error in '#{config_file_path}'", 2)
    end
  end
  Cheffish.profiled_config # This adds support for Chef profiles
end
```

This will handle everything including environment variables.

You may also want to do this:

```ruby
Chef::Config.local_mode true
```

If you have your own configuration mechanism, you can either merge it with the Chef config using `Cheffish::MergedConfig.new(my_config, chef_config), or just pass it directly and ignore Chef.

#### Respecting local mode

If you want to work with local mode (spin up a chef-zero server), you will need to spin it up.  You can use this code to do that:

```ruby
require 'chef/application'

Chef::Application.setup_server_connectivity
```

The Chef server URL will be in `Chef::Config.chef_server_url`.

Use this code to stop it when you are done with it:

```ruby
Chef::Application.destroy_server_connectivity
```

### Listening to Metal: implementing ActionHandler

`ActionHandler` is how Metal communicates back to your application. It will report progress and tell you when it updates things, so that you can print that information to the user (whether it be to the console or to a UI). To create an ActionHandler, you implement these methods:

```ruby
require 'chef_metal/action_handler'

class MyActionHandler < ChefMetal::ActionHandler
  # Loads node (which is a hash witha  bunch of attributes including 'name')
  def initialize(name, my_storage)
    @node = my_storage.load(name) || { 'name' => name }
    super(@name)
    @my_storage = my_storage
  end

  # Globally unique identifier for this machine.  For Chef, we use
  # <chef_server_url>/nodes/#{name}.  Does not have to be a URL.
  def id
    "#{@my_storage.url}/#{name}"
  end

  def save(action_handler)
    # much-vaunted idempotence
    if @my_storage.node_is_different(name, @node)
      action_handler.perform_action "save #{name} to storage" do
        @my_storage.save(@node)
      end
    end
  end
end
```

### Storing machine data: implementing MachineSpec

`MachineSpec` is the way you communicate the persisted state of a machine to metal (including save and load).

MachineSpec has a save() method that saves the machine location data (like its instance ID or Vagrantfile) to persistent storage for later retrieval. For chef-client, this location is a Chef node. For other applications, you may prefer to store this sort of persistent data elsewhere (test-kitchen has its own server state storage). To do that, you will override `MachineSpec` and implement the `save` method (as well as create a method to instantiate YourMachineSpec by loading it back in).

In many Chef-centric cases,

If you are OK with just storing the nodes in the Chef server, then you can just use the `ChefMachineSpec` to take care of saving and loading:

```ruby
require 'cheffish'
require 'chef_metal/chef_machine_spec'

chef_server = Cheffish.chef_server_for(config)
machine_spec = ChefMetal::ChefMachineSpec.new(machine_name, chef_server)
```

### Instantiating a driver

When you want to work with machines, you need a driver.  There are two principal reasons to get a driver.  First, for connect, destroy and delete type operations, you may want to work with an *existing* machine, defined by a machine_spec.  Second, to create a *desired* machine (allocate and ready_machine), you will want to create a driver straight from configuration or from a driver URL.

To get a driver URL from config:

```ruby
require 'chef_metal'
driver = ChefMetal.driver_for_url(chef_config[:driver], chef_config)
```

To get a driver URL from a machine spec:

```ruby
if machine_spec.driver_url
  driver = ChefMetal.driver_for_url(machine_spec.driver_url, chef_config)
end
```

### Creating a machine

To create a machine, you do this:

```ruby
machine_options = ChefMetal.config_for_url(driver.driver_url, chef_config)
ChefMetal.allocate_machine(action_handler, machine_spec, machine_options)
ChefMetal.ready_machine(action_handler, machine_spec, machine_options)
```

### Creating multiple machines in parallel

```ruby
driver = ChefMetal.driver_for_url(chef_config[:driver], chef_config)
machine_options = ChefMetal.config_for_url(driver.driver_url, chef_config)
machine_options = Cheffish::MergedConfig.new(machine_options, { :convergence_options => { :chef_server => Cheffish.default_chef_server(chef_config) } })
specs_and_options = {}
machine_specs.each do |machine_spec|
  specs_and_options[machine_spec] = machine_options
end
driver.allocate_machines(action_handler, specs_and_options)
driver.ready_machines(action_handler, specs_and_options)
```

NOTE: if you have specific options for each individual machine, you can use `Cheffish::MergedConfig.new({ :machine_options => new_options }, machine_options)` instead of `machine_options` inside the loop.

### Connecting to, destroying or stopping a machine

```ruby
driver.connect_to_machine(action_handler, machine_spec, machine_options)
driver.destroy_machine(action_handler, machine_spec, machine_options)
driver.stop_machine(action_handler, machine_spec, machine_options)
driver.destroy_machines(action_handler, specs_and_options)
driver.stop_machines(action_handler, specs_and_options)
```
