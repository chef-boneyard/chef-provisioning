# Chef Metal Parallelization

Provisioning clusters with a lot of machines would be horrifically slow if you had to do it one machine at a time.  Fortunately, Chef Metal 0.11 proffers powerful parallelization primitives, and even parallelizes machines by default wherever it can!

Here we'll describe how that works.

## Default parallelization

By default, whenever you write `machine` resources several times in a row, Chef Metal notices and parallelizes them with a `machine_batch`.  So, if you write a recipe like this:

```ruby
# In recipe
machine 'a'
machine 'b'
machine 'c'
```

Then the output will look a bit like this:

```
$ CHEF_DRIVER=fog:AWS chef-apply cluster.rb
...
Converging 1 resources
Recipe: @recipe_files::/Users/jkeiser/oc/environments/metal-test-local/cluster.rb
  * machine_batch[default] action converge
    - [a] creating machine a on fog:AWS:862552916454
    - [a]   key_name: "metal_default"
    - [a]   tags: {"Name"=>"a", "BootstrapId"=>"http://localhost:8889/nodes/a", "BootstrapHost"=>"Johns-MacBook-Pro-2.local", "BootstrapUser"=>"jkeiser"}
    - [a]   name: "a"
    - [b] creating machine b on fog:AWS:862552916454
    - [b]   key_name: "metal_default"
    - [b]   tags: {"Name"=>"b", "BootstrapId"=>"http://localhost:8889/nodes/b", "BootstrapHost"=>"Johns-MacBook-Pro-2.local", "BootstrapUser"=>"jkeiser"}
    - [b]   name: "b"
    - [c] creating machine c on fog:AWS:862552916454
    - [c]   key_name: "metal_default"
    - [c]   tags: {"Name"=>"c", "BootstrapId"=>"http://localhost:8889/nodes/c", "BootstrapHost"=>"Johns-MacBook-Pro-2.local", "BootstrapUser"=>"jkeiser"}
    - [c]   name: "c"
    - [b] machine b created as i-eb778fb9 on fog:AWS:862552916454
    - create node b at http://localhost:8889
    -   add normal.tags = nil
    -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", "driver_version"=>"0.5.beta.2", "server_id"=>"i-eb778fb9", "creator"=>"user/jkeiser", "allocated_at"=>"2014-05-31 03:40:16 UTC", "key_name"=>"metal_default"}}
    - [a] machine a created as i-e9778fbb on fog:AWS:862552916454
    - create node a at http://localhost:8889
    -   add normal.tags = nil
    -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", "driver_version"=>"0.5.beta.2", "server_id"=>"i-e9778fbb", "creator"=>"user/jkeiser", "allocated_at"=>"2014-05-31 03:40:16 UTC", "key_name"=>"metal_default"}}
    - [c] machine c created as i-816d95d3 on fog:AWS:862552916454
    - create node c at http://localhost:8889
    -   add normal.tags = nil
    -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", "driver_version"=>"0.5.beta.2", "server_id"=>"i-816d95d3", "creator"=>"user/jkeiser", "allocated_at"=>"2014-05-31 03:40:17 UTC", "key_name"=>"metal_default"}}
    - [b] waiting for b (i-eb778fb9 on fog:AWS:862552916454) to be ready ...
    - [c] waiting for c (i-816d95d3 on fog:AWS:862552916454) to be ready ...
    - [a] waiting for a (i-e9778fbb on fog:AWS:862552916454) to be ready ...
...
        Running handlers:
        Running handlers complete

        Chef Client finished, 0/0 resources updated in 4.053363945 seconds
    - [c] run 'chef-client -l auto' on c

Running handlers:
Running handlers complete
Chef Client finished, 1/1 resources updated in 59.64014 seconds
```

You'll notice that, at the very end, it says 1/1 resources.  This is because the three machines are *replaced* with a `machine_batch` resource that does the parallelization.

Since it's automatic, Chef Metal tries not to be overly aggressive:
- Complex scripts don't parallelize: If you write `machine`, then put another resource in between (like `remote_file`), then another `machine`, Chef Metal will run the machines sequentially instead of parallelizing.
- Different actions don't parallelize: `machine 'a'` followed by `machine 'b' do action :delete end` will not parallelize.

Default parallelization can be turned off by writing `auto_batch_machines = false` in a recipe or `auto_batch_machines false` in your Chef config (knife.rb or client.rb).

## machine_batch

`machine_batch` can also be used explicitly.  You can write a `machine_batch` that does a simple `:setup`, `:converge`, `:stop` or `:delete` (among others) like this:

```ruby
# In recipe
machine_batch do
  action :setup
  machines 'a', 'b', 'c', 'd', 'e'
end
```

You can even mix and match different types of machines:

```ruby
machine_batch do
  machine 'db' do
    recipe 'mysql'
  end
  1.upto(50) do |i|
    machine "#{web}#{i}" do
      recipe 'apache'
    end
  end
end
```

Even machines with different drivers and chef_servers can be mixed and parallelized. 50 in AWS and 50 in Azure?  No problem!  Run them all at once, in the same batch.
