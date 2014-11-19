[![Stories in Ready](https://badge.waffle.io/patrick-wright/chef-provisioning-test-suite.png?label=ready&title=Ready)](https://waffle.io/patrick-wright/chef-provisioning-test-suite)
[![Build Status](https://travis-ci.org/patrick-wright/chef-provisioning-test-suite.svg?branch=master)](https://travis-ci.org/patrick-wright/chef-provisioning-test-suite)

chef-provisioning-test-suite
=====================
I don't like the name either.  Throw ideas my way.

## Usage
Here's an example how tests can be formulated by combining recipes in a certain order.
```
rake bundle && rake berks

# manual example
bundle exec chef-client -z -o driver::vagrant,test::create-destroy

# rspec goodies: cleanup, log capture, formatting
rspec spec -t driver_family:cloud # run all cloud driver tests
```

"Hey! That looks just like chef-metal proper!"  And, you would be correct. "So, what gives?"  Well, we are executing standard approaches to running chef-metal and validating that they execute without error.  This work leads to ability to run chef-metal convergence and verify the results with tests.

## The Tests
The tests are pre-configured combinations that will eventually be more dynamic.  Tests will also be easily configured to allow filtering (cli or config api) of what tests should be run for a given execution.
#### Spec Tagging Options
`driver_family` : cloud, vm, container

`driver` : aws, fog, vagrant

Future tags : platform / version, chef server type (hosted, cluster)

## What is this project?
This project is intended to execute all the components that make up the chef-metal ecosystem, and validate they behave as expected.  This includes all the "opscode" chef-metal drivers via chef-zero, Chef Server clusters, or Hosted Chef.  Other facets include OS platorm/versions, including Windows, and cross-platform interaction.

## What does it prove?
### Now
Currently, this project proves that chef-metal and some drivers (master branches) can be combined with basic recipes and executed without raising critical errors.  The project is growing rapidly. Ideas and plans can be reviewed [here](docs/braindump.md)

### Goals
This project aims to prove cluster idempotence, and interchangeability between providers and recipes.  Other goals include ensuring key features of chef-metal work as intended e.g., parallel machine creation/convergence, and image creation/loading.

## Staying on Track
To give this test project a great chance of succees, we've decided to align our goals with Brett Pettichord's ["Seven Step to Test Automation Success"](http://www.testpoint.com.au/attachments/093_Seven%20Steps%20to%20Test%20Automation%20Success.pdf).

Follow our [progress](docs/pettichords_seven_steps.md)
