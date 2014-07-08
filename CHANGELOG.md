# Changelog

## 0.7 (7/8/2014)

- [AWS] More parallelism: make single call to AWS bootstrap many machines (if fog version supports it)
- [AWS] Fix bug when ~/.aws/config does not exist
- [AWS] Fix bug in Ruby 1.9 when fingerprints don't match (pkcs8 loading didn't work)

## 0.6.1 (6/18/2014)

- fix bootstrap when key is not yet specified

## 0.6 (6/18/2014)

- @thommay split the driver into subclasses for each provider instead of tons of if statements
- @lamont-granquist allow DigitalOcean to use SSH paths
- Use unix timestamps instead of strings (@thommay)
- Don't require PKCS8 to be installed

## 0.5.4 (6/10/2014)

- Fix PKCS8 fingerprint comparison on < 2.0

## 0.5.3 (6/5/2014)

- @thommay fix issue where keypair fingerprints don't compare correctly across machines

## 0.5.2 (6/4/2014)

- [DigitalOcean] Autoload ~/.tugboat file with credentials and defaults

## 0.5.1 (6/4/2014)

- [Openstack] @thommay fix for credentials retrieval

## 0.5 (6/4/2014)

- [Rackspace] @hhoover @thommay Rackspace support!
- [CloudStack] @marcusn CloudStack support!
- Adjust to chef-metal 0.11 interface
- Major refactor for readability
- [AWS] Make region part of fog:AWS URL: fog:AWS:<id>:<region> is canonical
- [AWS] Support fog:AWS:<profile>:<region> to override regionis now supported.
- [AWS] Much better support for regions and AWS environment variables
- @marcusn numerous bugfixes
- Fix PKCS8 crash on Ruby 2.0+
- Don't reboot server on every chef-client run if non-connectable
- Warn when username at time of creation is not the same as the current username (ssh might fail)
- @irvingpop speed up converges by downloading Chef from the remote machine (InstallSh instead of InstallCached)

## 0.4 (5/1/2014)

- Work with new Cheffish 0.4 inline_resource
- Increase stability of delete_machine in error conditions (@andrewdotn)
- [EC2] Support automatically-created PKCS#8 SHA1 fingerprints for keys
- [Openstack] Make floating IP attach work (@ohlol)
- [Openstack] Fill in "creator" field of provisioner_output (@wilreichert)

## 0.3.1 (4/13/2014)

- Treat EHOSTUNREACH as "machine not yet available"

## 0.3 (4/13/2014)

- Catch new initial connect timeout from chef-metal

## 0.2.1 (4/11/2014)

- Fix bug creating new machines

## 0.2 (4/11/2014)

- Support chef_server_timeout
- Fix provisioner_init (for kitchen-metal and metal executable)
