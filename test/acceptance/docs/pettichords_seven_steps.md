## Bret Pettichord's Seven Step to Automation Success Applied
This document outlines the concerted effort to building a quality, sustaining automated test suite for chef-metal by applying the ["Seven Steps"](http://www.testpoint.com.au/attachments/093_Seven%20Steps%20to%20Test%20Automation%20Success.pdf).

**This is a working document and will be updated as work progresses.**

### Improve the Testing Process
How has testing been executing up to this point?

### Define Requirements
[Working document](docs/braindump.md)
#### Near-term Goals
##### Focus: RC 1 (AWS Reinvent)
* chef-zero local only
* ubuntu 14.04
* windows 2012
* aws driver and vagrant driver are highest priority
* add in as many "opscode" drivers following
* create, verify, destroy test
* CI for cloud

##### Focus: Release 1.0
* hosted and chef server
* all "opscode" drivers
* all platforms
* more tests to cover core driver features

#### Long-term Goals
Focus: allthethings
* unix to windows and vice versa
* deeper driver validation
* building drivers
* embedding metal
* metal executables

### Prove the Concept
This project is the proof of concept which focuses primary on the configuration.  In other words, how many valid combinations of server type, platform, driver can I run against a suite of tests.  Multi-dimensional test configurations can get complicted very quickly.  The idea with this project was to stay as linear as possible and only branch if necessary.  If seemed reasonable to run a single config against a series of tests versus say a configuration of all drivers to run against a single server type, single platform, and single test.

### Champion Project Testablity
What type of testablity features have been developed into chef-metal?

Related note. From the start this project has been developed with three approaches to running the tests.

1. CLI
1. API
1. Config file (accepted by CLI)

### Design for Sustainablity
* Well defined configuration combinations (validated)
* rspec helpers for easily creating tests (almost DSL like)
* Modularized for future driver support

### Plan for Deployment
* CI plan
* Reporting and Reviewing results
* Community involvement (test project)

### Face the Challenges of Success
* doc doc and more doc
* define where manual testing fits
