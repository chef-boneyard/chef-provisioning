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

Bubbles is a big dude.  Bubbles is working on changing his name.

## Act I: Chef CI

In Act I, our heroes have built new features and want to test them, client against server, server against client.  Right now we're not talking about a variety of OS's, we're talking about bare minimum acceptance testing.

### CI

Jenna is developing a new feature for earrings to report whether they are on the left or right ear.  She wants to use system testing to verify her app.  She wants to use a vagrant box, and is willing to re-converge each time she runs.

Jenna will develop the tests, and Seth will place them on a trigger to run on each checkin.

Seth wants to support Jenna by running her tests automatically on every checkin, and creating a release build process that gates the release on the tests passing.  Robustness is extremely important here; any spurious failures will make CI untrustworthy and get it thrown out entirely.  Concurrency of a sort is important as well: Seth should be able to run multiple copies of the same test job in parallel on multiple machines, and they should not interfere with one another.  Clean starts are also important here: he should be able to clean up after failed runs, and start anew each time.

EC2 and OpenStack providers must be available and support the same CentOS that EC2 supports.

#### Single-client test

Jenna's task is to develop the test.

- She builds a Metal recipe that can spin up a client and a server:



- She runs this recipe



### CI

## Act II: CI (Full Acceptance)

## Act III: Local Development

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