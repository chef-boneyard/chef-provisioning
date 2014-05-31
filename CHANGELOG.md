# Changelog

## 0.5.beta.3 (5/30/2014)

- Much better support for regions and AWS environment variables
- @hhoover Rackspace support!
- @marcusn numerous bugfixes
- @marcusn CloudStack support!

## 0.5.beta.2 (5/27/2014)

- Fix PKCS8 crash on Ruby 2.0+
- Fix ability to update fog_key_pair

## 0.5.beta (5/23/2014)

- Major refactor for readability
- Adjust to new chef-metal interface

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
