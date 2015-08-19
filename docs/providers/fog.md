# Fog (Openstack, DigitalOcean and friends)

chef-provisioning also comes with a [Fog](http://fog.io/) provisioner that handles provisioning to Openstack, Rackspace, and other cloud drivers.  Before you begin, you will need to put your credentials in ~/.fog in the format [described in the getting started guide](http://fog.io/about/getting_started.html).

Once your credentials are in, basic usage looks like this:

```
export CHEF_DRIVER=fog:DigitalOcean
chef-client -z simple.rb
```

TODO: convert the rest of this from AWS to something still using Fog
TODO: Move this into the fog repo

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
