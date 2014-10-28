# Chef Metal Requirements

Chef Metal lets you describe and converge entire clusters of machines the same way you converge an individual machine: through Chef recipes and resources.  Its general use cases include:

- Keeping clusters in source control (production, preproduction, etc.)
- Spinning up a cluster
- Setup and upgrade multi-machine orchestration scenarios
- Creating small test clusters for CI or local tests
- Auto-scaling a cluster
- Moving a cluster from one set of machines to another
- Building images

## Dramatis Personae

Here are some of the sort of people we expect to use Chef Metal.  Any resemblance to persons either real or fictional is purely a resemblance to persons either real or fictional.

BlingCo is a manufacturer of Bling, a client/server jewelry management system where earrings and necklaces run a client OS and a jewelry box is installed with a server OS that tracks the jewelry.  The jewelry, and the jewelry boxes, are not controlled by BlingCo and may run the server or the clients on a variety of different OS's.  BlingCo would like to release a product that is reliable and easy to use, on all these platforms.

### Seth (QA)

Seth is a driven, passionate owner of quality management infrastructure. His job is to build the tests and continuous delivery infrastructure for BlingCo. Seth is annoyed that there are so many people named Seth, and has vowed that his childrens' names will be globally unique.

### Jenna (DevOps)

Jenna is a senior software developer at BlingCo. She has deep background in distributed systems, networking, databases and all things code; her knowledge of ops is much rustier.

### Bubbles (OpsDev)

Bubbles is a big dude. His hobbies include bar fights and defending his honor. He eats routers for breakfast, can configure a server in morse code, and knows a little Ruby too.

## Act I: CI

In Act I, our heroes are building a new feature and want to test it, client against server, server against client.

Jenna is developing a new feature for earrings to report whether they are on the left or right ear.  She wants to use system testing to verify her app: a real client and a real server, talking to each other.  She wants to use a local server, and is willing to re-converge each time she runs.  She sometimes develops on her Mac, meaning she needs to use VirtualBox to get a Linux VM, and sometimes on her Linux machine, where she can use LXC.

Seth wants to support Jenna by running her tests automatically on every checkin, and creating a release build process that gates the release on the tests passing.  Robustness is extremely important here; any spurious failures will make CI untrustworthy and get it thrown out entirely.  Concurrency of a sort is important as well: Seth should be able to run multiple copies of the same test job in parallel on multiple machines, and they should not interfere with one another.  Clean starts are also important here: he should be able to clean up after failed runs, and start anew each time.  Because Seth would like to use Travis, LXC is preferable to EC2 for speed purposes; Windows and other clients, however, will still require EC2.

### Full-Stack Install via LXC

Jenna's task is to develop the test.  The first thing she does is get Metal to *start* the client and server, and get them talking to each other:

1. She installs LXC.

2. She has a repository that has her cookbooks, data bags, roles, etc. in it:
   ```
   cookbooks/
     bling/
       recipes/
         server.rb
         client.rb
   ```
   It is worth noting that `client.rb` does a `search('tags:bling_server')`.

3. She builds a Metal recipe, `client_server.rb`:
   ```ruby
   machine 'myserver' do
     recipe 'bling::server'
     tag 'bling_server'
   end

   machine 'myclient' do
     recipe 'bling::client'
   end
   ```

4. She builds a Metal recipe that describes LXC containers in 'lxc_ubuntu.rb':
   ```ruby
   require 'chef_provisioning/lxc'
   with_provisioner ChefProvisioning::Provisioner::LXC.new
   with_provisioner_options { :template => 'ubuntu' }
   ```
**Ed.: should we build some kind of default mechanism, or global place to put these?**

5. She runs the recipes!
   `chef-client -z lxc_ubuntu.rb client_server.rb`

Now she has a client and a server, in LXC, registered against the same (local) chef instance.

### Full-Stack Install Via VirtualBox

Jenna goes home and wants to work on her OS X machine.  This means developing using VirtualBox VMs.

1. She installs vagrant and VirtualBox.

2. She builds a Metal recipe that describes the vagrant options and architecture: 'vagrant_linux.rb':
   ```ruby
   require 'chef_provisioning/vagrant'
   vagrant_cluster "#{Chef::Config.chef_repo_path}/vagrantboxes"
   vagrant_box 'precise64' do
     url 'http://files.vagrantup.com/precise64.box'
   end
   ```
   **Ed.: should we build some way to specify "current directory" or "test directory" or dispense with that entirely and allow relative directories?**

3. She runs the recipes!
   `chef-client -z vagrant_linux.rb client_server.rb`

### Writing System Tests With Kitchen

Now that the instance is installed, Jenna needs to write the actual test.  This is where test kitchen comes in!  Using the Metal driver for test kitchen, Jenna wants to write a test that will:

1. Bring up the server and client (connected to one another)
2. Verify that the earring is not on
3. Set the earring to the left ear
4. Verify that the earring is on the left ear

To do all these things, she just sets up Kitchen with her recipes and runs an rspec test:

1. Install the `kitchen-metal` driver.

2. Create a `kitchen.yml` file:
   ```yaml
   driver:
     name: metal
     layout: client_server.rb

   platforms:
     - name: lxc_ubuntu.rb

   suites:
     - type: host-rspec
       spec: spec/ear_detection.rb
   ```

3. Create the rspec test:
   ```ruby
   describe 'ear detection' do
     before :each do
       @server = Chef::Node.get('bling_server')
       @server_ip = @server['ip_address']
       @client = Chef::Node.get('bling_server')
       @client_ip = @client['ip_address']
     end

     after :each do
       HTTP.put("http://#{@client_ip}/reset", 'true')
     end

     it 'should start out not in any ear' do
       HTTP.get("http://#{@server_ip}/jewelry/bling_client")['ear'].should == 'none'
     end

     it 'should reflect changed ear values' do
       HTTP.put("http://#{@client_ip}/ear", 'left')
       HTTP.get("http://#{@server_ip}/jewelry/bling_client")['ear'].should == 'left'
     end
   end
   ```

When she runs `kitchen verify`, all these things run and life is good for earring wearers everywhere.

### Running It In CI

Seth hooks up Jenna's test to Travis, using a traditional `.travis.yml` file that looks like this:

```yaml
script: bundle exec kitchen verify
```

And creates a `Gemfile` including `test-kitchen` and `kitchen-metal`:

```ruby
source 'https://rubygems.org'

gem 'test-kitchen'
gem 'kitchen-metal'
```

And we're done!  At this point, on every single checkin, Travis will bring up two LXC instances, run the server and client on them, and run the earring movement test.


## Act II: Multiple Unix OS Testing

Now that she's tested that the feature works on Linux, Jenna would like to run the tests against

### Testing Multiple Client OS's With Metal

Once this is all done, Jenna would like to run the same tests with all client OS's hooked up to all server OS's.  To do this, she will create a new Metal topology recipe server_and_many_clients.rb:

And modify `.kitchen.yml` to use it:

### Testing Multiple Server OS's With Kitchen

Now Jenna wants to use multiple server OS's.  To do this, she creates Metal recipes for each OS, and modifies the Kitchen platforms to add the other OS's:

### CI With Multiple Server OS's

Because `kitchen verify` is doing all the work, Seth doesn't have to do anything.  We're already up with CI on multiple server OS's!


## Act III: Orchestration


## Act IV: Windows

### Testing Windows Client Alongside Others

### CI With Windows Server

The difference here is EC2 credentials need to end up on Travis.  Here's how Seth does that securely:


## Act V: Stress!

This is where we support large numbers of machines, in a performant way.  Also, EC2.


## Act VI: Production

This is where we talk about how a large production cluster can be deployed, updated and versioned.


## Act VII: Local Development

This is where we support everything from other host OS's.  It is also where we solve the problem of sharing data between the host and guest.
