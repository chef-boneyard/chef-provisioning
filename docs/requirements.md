# Chef Metal Requirements

Chef Metal lets you describe and converge entire clusters of machines the same way you converge an individual machine: through Chef recipes and resources.  Its general use cases include:

- Keeping clusters in source control (production, preproduction, etc.)
- Spinning up a cluster 
- Setup and upgrade multi-machine orchestration scenarios
- Creating small test clusters for CI or local tests
- Auto-scaling an cluster
- Moving a cluster from one set of machines to another
- Building images

## Dramatis Personae

Here are some of the sort of people we expect to use Chef Metal.  Any resemblance to persons either real or fictional is purely a resemblance to persons either real or fictional.

BlingCo is a manufacturer of Bling, a client/server jewelry management system where earrings and necklaces run a client OS and a jewelry box is installed with a server OS that tracks the jewelry.  The jewelry, and the jewelry boxes, are not controlled by BlingCo and may run the server or the client on a variety of different OS's.  There may be an arbitrary number of clients, and there may be .  BlingCo would like to release a product that is reliable and easy to use, on all these platforms.

### Seth (QA)

Seth is a driven, passionate owner of quality management infrastructure. His job is to build the tests and continuous delivery infrastructure for BlingCo. Seth is annoyed that there are so many people named Seth, and has vowed that his childrens' names will be globally unique.

### Jenna (DevOps)

Jenna is a senior software developer at BlingCo. She has deep background in distributed systems, networking, databases and all things code; her knowledge of ops is much rustier.

### Bubbles (OpsDev)

Bubbles is a big dude. He eats routers for breakfast, can configure a server in morse code, and knows a little Ruby too. Bubbles is working on changing his name.

## Act I: Chef CI

In Act I, our heroes have built new features and want to test them, client against server, server against client.  Right now we're not talking about a variety of OS's, we're talking about bare minimum acceptance testing.

### CI

Jenna is developing a new feature for earrings to report whether they are on the left or right ear.  She wants to use system testing to verify her app.  She wants to use a vagrant box, and is willing to re-converge each time she runs.

Jenna will develop the tests, and Seth will place them on a trigger to run on each checkin.

Seth wants to support Jenna by running her tests automatically on every checkin, and creating a release build process that gates the release on the tests passing.  Robustness is extremely important here; any spurious failures will make CI untrustworthy and get it thrown out entirely.  Concurrency of a sort is important as well: Seth should be able to run multiple copies of the same test job in parallel on multiple machines, and they should not interfere with one another.  Clean starts are also important here: he should be able to clean up after failed runs, and start anew each time.

EC2 and OpenStack providers must be available and support the same CentOS that EC2 supports.

#### Single-client install

Jenna's task is to develop the test.  The first thing she does is get Metal to *start* the client and server, and get them talking to each other:

1. She installs VirtualBox and Vagrant.

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

4. She builds a Metal recipe that describes *where* to spin up the client and server, and what architecture to do it on: 'vagrant.rb':
   ```ruby
   require 'chef_metal/vagrant'
   vagrant_cluster "#{Chef::Config.chef_repo_path}/vagrantboxes"
   vagrant_box 'precise64' do
     url 'http://files.vagrantup.com/precise64.box' 
   end
   ```
   **Ed.: should we build some kind of default mechanism, or global place to put these?**
   **Ed.: should we build some way to specify "current directory" or "test directory" or dispense with that entirely and allow relative directories?**

5. She runs the recipes!
       chef-client -z vagrant.rb client_server.rb

Now she has a client and a server, registered against the same (local) chef instance.

### Local Test

Now that the instance is tested, Jenna needs to write the actual test.  This is where test kitchen comes in!  Using the Metal driver for test kitchen, Jenna wants to write a test that will:

1. Bring up the server and client (connected to one another)
2. Verify that the earring is not on
3. Set the earring to the left ear
4. Verify that the earring is on the left ear
5. Set the earring to the right ear
6. Verify that the earring is on the right ear

To do all these things, she has to:

1. Install the `kitchen-metal` driver.

2. Create a `kitchen.yml` file:
   ```
   ```

3. Create the rspec test:
   ```
   ```

When she runs `kitchen verify`, all these things run and life is good for earring wearers everywhere.

### CI

Seth hooks up Jenna's test to Travis, using a traditional `.travis.yml` file that looks like this:

```
```

And we're done!  At this point, on every single checkin, Travis will bring up two Vagrant / VirtualBox instances, run the server and client on them, and run the earring movement test.

## Act II: CI (Full Acceptance)

This is where we support other OS's, from an Ubuntu host.

## Act III: Local Development

This is where we support everything from other host OS's.  It is also where we solve the problem of sharing data between the host and guest.

## Act IV: Stress!

## Act V: Production




## 0.9: Chef CI

Our most pressing need, and our first use case, is leveling up Chef's CI infrastructure.  To do that, we'd like to be able to run tests that span multiple machines, particularly

### Small CI test clusters

### Kitchen Integration

### Chef test clusters

The specific test clusters we must be able to support

### Permutations

Initial providers must be openstack, EC2, and vagrant+virtualbox.  These are the providers Chef uses internally at the moment.  Host OS's (places Metal runs on) must include OS X and Ubuntu.  Guest OS's include Ubuntu, CentOS and Red Hat on all providers.

## 1.0: Windows

Metal *will not go 1.0* without Windows support.  It already exists to a large degree, but Windows Host support is not yet tested.

### Permutations

This release will support Windows Guest OS's on all providers.



### HA test clusters

Still on the subject of HA test clusters

## Future

### Container Support

## 
