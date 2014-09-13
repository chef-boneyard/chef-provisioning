Frequently Asked Questions
==========================

**Q:** Can I create machines without provisioning them?

**A:** To create machines without provisioning, you can use the `:setup` action.  That will get chef-client installed and the client/node created, but will not actually run it.  `:allocate` goes even further: it will ask Amazon to spin up the machine but will not wait for it to be spun up (you can provision it later with metal still, don't worry).  `:ready` is in between and will spin up the machine but will not install chef-client on it.

If you want to create the machines without *any* provisioning at all--without even waiting for them to be provisioned--you can use the :allocate action.  All that will do is send the request to AWS to spin up the machines and then let you continue.  If you do this:

```ruby
machine 'x' do
  action :allocate
end

<do other recipe stuff>

machine 'x' do
  recipe 'blah'
end
```

Then everything will still work: the second machine declaration will "catch" the machine and provision it, so to speak.  Yay idempotency!

Even more interesting in combination with machine_batch:

```ruby
machine_batch do
  machines 'a', 'b', 'c'
  action :allocate
  # NOTE: you could have also written out each machine as a full machine delcaration here a la machine 'x' do ... end
end

... do other stuff ...

machine_batch do
  machine 'a' do
    recipe 'a'
  end
  machine 'b' do
    recipe 'b'
  end
  ...
end
```

This will get Amazon spinning up all your machines at once, at the beginning, and then your recipe can do other things ... then when you're done with other things, the second machine_batch declaration will "catch" the machines and get them provisioned.

**Q:** I need to be sure *all* my machines have registered themselves and updated before I install my actual app.  How?

**A:** A very common, primitive, and effective orchestration technique with Chef Metal is to fully :converge the machines, but not run any recipes (or just run some base recipes) so that the whole data center is registered with the Chef server, ohai'd, and updated before the real application install begins.  This lets you get the benefits of parallelism at the beginning--set up *all* of your servers at once--and lets you converge the machines later in whatever order you want.

In fact, often you won't have to do any ordering at all if you do this, since Chef now knows all the machines' IPs and they can connect to each other.  Typically, as long as you can put the IPs of the other machines in config files, applications will wait until the other machines spin up.

It looks something like this:

```ruby
machine_batch do
  [ 'db', 'web1', 'web2', 'web3' ].each do |name|
    machine name do
      recipe 'base' # Don't converge machine-specific stuff yet, but let's get apt updated and stuff in parallel
    end
  end
end

# Converge the database first
machine 'db' do
  recipe 'mysql'
end

# Now converge the web machines
machine_batch do
  [ 'web1', 'web2', 'web3' ].each do |name|
    machine name do
      recipe 'apache2'
    end
  end
end
```

**Q:** Where does machine information get stored?

**A:** When you first provision a machine with Metal (like, when you allocate it), Chef Metal creates a **Chef node** for the machine with a special attribute `{ "metal": { "location": { ... }}}`. Inside there is a hash of information identifying the server, including a `driver_url`.  The driver_url is the same thing you specify in `CHEF_DRIVER` and `with_driver`.  Different drivers will store different information; the AWS driver, for instance, stores the instance ID (`i-19834b 13`).

If you are running against a Chef server, this node lives on the Chef server and anyone else with permissions can see it.  If you are running in local mode, the nodegets saved to <chef_repo_path>/nodes/node_name.json (which you can look at on the hard drive).  If you haven't set anything, `<chef_repo_path>` will generally be the current directory.

When a second chef-client run goes off, the machine resource looks up the node and sees the instance ID already in it.  It uses the `driver_url` to load the AWS driver and your credentials, and checks if the instance is powered up and if ssh is available.

**Q:** I've been using custom bootstrap files with `knife bootstrap`.  Does Chef Metal support this?

**A:** Short answer: no.  Metal uses a different mechanism to register the machine with Chef and set up chef-client on it.

However, Chef Metal has a lot of capabilities that were not available with `knife bootstrap` and in many cases makes it unnecessary.  A few examples:

1. Many custom bootstraps exist to get secrets and other files up to the machine.  In Chef Metal, you can do that like this:

```ruby
machine 'foo' do
  file '/remote/path.txt', '/local/path.txt'
end
```

2. Other times, bootstrap files are used to do "pre-provisioning" recipes that set things up that need to be there before the main recipes run.  With Chef Metal, you can simply use the machine resource twice to get separate chef-client runs:

```ruby
machine 'foo' do
  recipe 'base' # Install the base stuff on the machine, connect it to AD, etc.
end
machine 'foo' do
  recipe 'my_web_app' # Install everything else
end
```

This will converge twice: the first converge will run the `base` cookbook and the second will run `my_web_app`.
