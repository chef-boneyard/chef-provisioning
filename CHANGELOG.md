# Change Log

## [v1.9.1](https://github.com/chef/chef-provisioning/tree/v1.9.1) (2016-08-11)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.9.0...v1.9.1)

**Merged pull requests:**

- allows cheffish 3.0 to stop pulling in compat\_resource [\#534](https://github.com/chef/chef-provisioning/pull/534) ([lamont-granquist](https://github.com/lamont-granquist))

## [v1.9.0](https://github.com/chef/chef-provisioning/tree/v1.9.0) (2016-08-11)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.8.1...v1.9.0)

**Closed issues:**

- Uninitialized constant Chef::Resource::Machine [\#531](https://github.com/chef/chef-provisioning/issues/531)

## [v1.8.1](https://github.com/chef/chef-provisioning/tree/v1.8.1) (2016-08-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.8.0...v1.8.1)

**Merged pull requests:**

- Cleaning up a deprecation warning [\#530](https://github.com/chef/chef-provisioning/pull/530) ([tyler-ball](https://github.com/tyler-ball))

## [v1.8.0](https://github.com/chef/chef-provisioning/tree/v1.8.0) (2016-06-16)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.7.1...v1.8.0)

**Closed issues:**

- machine\_batch doesn't clearly mention which machine failed [\#499](https://github.com/chef/chef-provisioning/issues/499)
- Flexible install\_command. Do not assume internet acces.  [\#474](https://github.com/chef/chef-provisioning/issues/474)

**Merged pull requests:**

- Fix WARN: nil is an invalid value for output\_key\_format [\#520](https://github.com/chef/chef-provisioning/pull/520) ([christinedraper](https://github.com/christinedraper))
- Add support for custom :install\_sh\_url [\#515](https://github.com/chef/chef-provisioning/pull/515) ([SIGUSR2](https://github.com/SIGUSR2))
- error handling for machine\_batch resource [\#500](https://github.com/chef/chef-provisioning/pull/500) ([ckaushik](https://github.com/ckaushik))

## [v1.7.1](https://github.com/chef/chef-provisioning/tree/v1.7.1) (2016-05-17)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.7.0...v1.7.1)

**Merged pull requests:**

- install\_sh and install\_cached convergence strategies trigger chef-client with -c flag [\#518](https://github.com/chef/chef-provisioning/pull/518) ([poliva83](https://github.com/poliva83))

## [v1.7.0](https://github.com/chef/chef-provisioning/tree/v1.7.0) (2016-04-06)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.6.0...v1.7.0)

**Merged pull requests:**

- Use mixlib-install 1.0 [\#512](https://github.com/chef/chef-provisioning/pull/512) ([jkeiser](https://github.com/jkeiser))
- Allow newer inifile gem [\#509](https://github.com/chef/chef-provisioning/pull/509) ([pburkholder](https://github.com/pburkholder))

## [v1.6.0](https://github.com/chef/chef-provisioning/tree/v1.6.0) (2016-02-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.5.1...v1.6.0)

**Implemented enhancements:**

- Custom port forwards. [\#445](https://github.com/chef/chef-provisioning/pull/445) ([causton81](https://github.com/causton81))

**Fixed bugs:**

- Chef::Exceptions::ContentLengthMismatch Response body length XXXX does not match HTTP Content-Length header XXXX [\#446](https://github.com/chef/chef-provisioning/issues/446)
- Updating to the latest release of net-ssh to consume net-ssh/net-ssh\#280 [\#485](https://github.com/chef/chef-provisioning/pull/485) ([tyler-ball](https://github.com/tyler-ball))

**Merged pull requests:**

- Fix Provisioning with Cheffish 1.x [\#496](https://github.com/chef/chef-provisioning/pull/496) ([jkeiser](https://github.com/jkeiser))
- Bump revision to 1.6.0 [\#493](https://github.com/chef/chef-provisioning/pull/493) ([jkeiser](https://github.com/jkeiser))
- Add "rake changelog" task [\#491](https://github.com/chef/chef-provisioning/pull/491) ([jkeiser](https://github.com/jkeiser))
- Stop using Chef::Provider::ChefNode directly \(cheffish 2.0 compat\) [\#490](https://github.com/chef/chef-provisioning/pull/490) ([jkeiser](https://github.com/jkeiser))
- Allow cheffish 2.0 as a dep [\#489](https://github.com/chef/chef-provisioning/pull/489) ([jkeiser](https://github.com/jkeiser))

## [v1.5.1](https://github.com/chef/chef-provisioning/tree/v1.5.1) (2015-12-10)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.5.0...v1.5.1)

**Merged pull requests:**

- Require ResourceBuilder file before monkeypatching to ensure it is already defined [\#478](https://github.com/chef/chef-provisioning/pull/478) ([tyler-ball](https://github.com/tyler-ball))
- Ensure target directory exists when using write\_file with WinRM [\#471](https://github.com/chef/chef-provisioning/pull/471) ([xenolinguist](https://github.com/xenolinguist))

## [v1.5.0](https://github.com/chef/chef-provisioning/tree/v1.5.0) (2015-10-27)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.4.1...v1.5.0)

**Fixed bugs:**

- :converge action should not re-install chef-client if the desired version is already installed [\#428](https://github.com/chef/chef-provisioning/issues/428)
- SSH available timeout needs to be configurable [\#362](https://github.com/chef/chef-provisioning/issues/362)
- Making available? timeout use provided ssh\_options, fixes \#362 [\#466](https://github.com/chef/chef-provisioning/pull/466) ([tyler-ball](https://github.com/tyler-ball))
- Pinning to mixlib-install 0.7.0 until 1.0 is out [\#464](https://github.com/chef/chef-provisioning/pull/464) ([tyler-ball](https://github.com/tyler-ball))
- Added bootstrap\_no\_proxy support [\#458](https://github.com/chef/chef-provisioning/pull/458) ([jsmartt](https://github.com/jsmartt))

**Closed issues:**

- The action "stop" on a Machine resource does not appear to work [\#463](https://github.com/chef/chef-provisioning/issues/463)
- machine chef-client run output not logging to provisioner chef-client output [\#274](https://github.com/chef/chef-provisioning/issues/274)

**Merged pull requests:**

- Add gemspec files to allow bundler to run from the gem [\#461](https://github.com/chef/chef-provisioning/pull/461) ([ksubrama](https://github.com/ksubrama))
- Pin mixlib-install more strictly. [\#459](https://github.com/chef/chef-provisioning/pull/459) ([sersut](https://github.com/sersut))

## [v1.4.1](https://github.com/chef/chef-provisioning/tree/v1.4.1) (2015-09-30)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.4.0...v1.4.1)

**Fixed bugs:**

- ohai\_hints should be be created at c:\chef\ohai\hints when provisioning windows nodes [\#433](https://github.com/chef/chef-provisioning/issues/433)
- Fix install\_sh\_arguments passing after the conversion to mixlib-install [\#452](https://github.com/chef/chef-provisioning/pull/452) ([irvingpop](https://github.com/irvingpop))
- Windows ohai hints, fixes \#433 [\#435](https://github.com/chef/chef-provisioning/pull/435) ([hh](https://github.com/hh))

## [v1.4.0](https://github.com/chef/chef-provisioning/tree/v1.4.0) (2015-09-16)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.3.0...v1.4.0)

**Implemented enhancements:**

- Provisioning driver generator script [\#395](https://github.com/chef/chef-provisioning/issues/395)
- Marking lxc and hanlon as seeking maintainers [\#440](https://github.com/chef/chef-provisioning/pull/440) ([tyler-ball](https://github.com/tyler-ball))
- Adding additional resource attributes for load\_balancer and machine\_image [\#436](https://github.com/chef/chef-provisioning/pull/436) ([tyler-ball](https://github.com/tyler-ball))
- Specify additional machine\_options from the resource attributes [\#424](https://github.com/chef/chef-provisioning/pull/424) ([tyler-ball](https://github.com/tyler-ball))
- Adding ignore\_converge\_failure option, fixes \#393 [\#414](https://github.com/chef/chef-provisioning/pull/414) ([tyler-ball](https://github.com/tyler-ball))
- Add a generic rspec module, and use and test it via the generator script. [\#408](https://github.com/chef/chef-provisioning/pull/408) ([randomcamel](https://github.com/randomcamel))

**Fixed bugs:**

- Provisioning fails with chef api error [\#394](https://github.com/chef/chef-provisioning/issues/394)
- specifying an audit-mode in a machine's run\_list fails the provisioning run. [\#393](https://github.com/chef/chef-provisioning/issues/393)
- machine\_file resource does not work properly using with\_machine\_options [\#390](https://github.com/chef/chef-provisioning/issues/390)
- install\_sh.rb has an issue with bootstrap [\#380](https://github.com/chef/chef-provisioning/issues/380)
- Metal command --help doesn't show or explain  command arguments [\#71](https://github.com/chef/chef-provisioning/issues/71)
- Added missing arguments to call of chef install shell script. [\#439](https://github.com/chef/chef-provisioning/pull/439) ([tarak](https://github.com/tarak))
- Add provides statements to providers to avoid chef-client warnings [\#416](https://github.com/chef/chef-provisioning/pull/416) ([stevendanna](https://github.com/stevendanna))
- Run our tests in a matrix of Chef client versions. [\#415](https://github.com/chef/chef-provisioning/pull/415) ([randomcamel](https://github.com/randomcamel))
- Upload the PS1 script and run directly [\#410](https://github.com/chef/chef-provisioning/pull/410) ([thommay](https://github.com/thommay))
- bump mixlib-install version [\#406](https://github.com/chef/chef-provisioning/pull/406) ([thommay](https://github.com/thommay))
- /etc/os-release support, yum support, package\_metadata option [\#315](https://github.com/chef/chef-provisioning/pull/315) ([glennmatthews](https://github.com/glennmatthews))

**Closed issues:**

- Converge fails when /tmp/chef-install.sh doesn't exist [\#423](https://github.com/chef/chef-provisioning/issues/423)
- Error forwarding port: could not forward 8889 or 0  [\#392](https://github.com/chef/chef-provisioning/issues/392)
- Chef Provisioning- Vagrant [\#372](https://github.com/chef/chef-provisioning/issues/372)
- chef-provisioning bootstrap fails  [\#359](https://github.com/chef/chef-provisioning/issues/359)

**Merged pull requests:**

- Remove dependency on chef gem [\#441](https://github.com/chef/chef-provisioning/pull/441) ([ksubrama](https://github.com/ksubrama))
- Adding a CONTRIBUTING document [\#437](https://github.com/chef/chef-provisioning/pull/437) ([tyler-ball](https://github.com/tyler-ball))
- Major generator/spec/Travis improvements [\#426](https://github.com/chef/chef-provisioning/pull/426) ([randomcamel](https://github.com/randomcamel))
- Add gem version badges for core + drivers. [\#412](https://github.com/chef/chef-provisioning/pull/412) ([randomcamel](https://github.com/randomcamel))

## [v1.3.0](https://github.com/chef/chef-provisioning/tree/v1.3.0) (2015-08-05)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.2.1...v1.3.0)

**Implemented enhancements:**

- expose machine\_spec.from\_image to allocate\_machine [\#366](https://github.com/chef/chef-provisioning/pull/366) ([mwrock](https://github.com/mwrock))

**Fixed bugs:**

- chef 12.4.0 and chef-provisioning have a problem when bootstrapping a node [\#377](https://github.com/chef/chef-provisioning/issues/377)
- Add a version compatibility check to ChefDK's `chef verify` [\#355](https://github.com/chef/chef-provisioning/issues/355)
- Unit tests and checkstyle? [\#180](https://github.com/chef/chef-provisioning/issues/180)
- Hardware matching [\#135](https://github.com/chef/chef-provisioning/issues/135)
- Data center abstraction [\#132](https://github.com/chef/chef-provisioning/issues/132)
- Machine migration [\#130](https://github.com/chef/chef-provisioning/issues/130)
- Chef environment on remote machines [\#88](https://github.com/chef/chef-provisioning/issues/88)
- metal command seems to not use .chef/knife.rb.  [\#70](https://github.com/chef/chef-provisioning/issues/70)
- metal binary complains about private key [\#65](https://github.com/chef/chef-provisioning/issues/65)
- Xen server VM provisioner [\#2](https://github.com/chef/chef-provisioning/issues/2)
- docs for VMware vCloud Air [\#368](https://github.com/chef/chef-provisioning/pull/368) ([hh](https://github.com/hh))

**Closed issues:**

- NoMethodError: undefined method `encoding' [\#405](https://github.com/chef/chef-provisioning/issues/405)
- \[Feature Request\] Allow chef-provisioning to force a recipe to run, even if it doesn't think it needs to be run [\#399](https://github.com/chef/chef-provisioning/issues/399)
- Set up minimal Travis build [\#397](https://github.com/chef/chef-provisioning/issues/397)
- Chef Metal with 1.0 [\#396](https://github.com/chef/chef-provisioning/issues/396)
- Non-Windows instances with a virtualization type of 'hvm' are currently not supported for this instance type [\#388](https://github.com/chef/chef-provisioning/issues/388)
- machine resource fails if audit failures occur [\#387](https://github.com/chef/chef-provisioning/issues/387)
- What does the error "missing required parameter name" mean [\#386](https://github.com/chef/chef-provisioning/issues/386)
- Can't connect to EC2 instance in VPC with public IP [\#385](https://github.com/chef/chef-provisioning/issues/385)
- Windows hosts are bootstrapped with the wrong url for chef-client [\#327](https://github.com/chef/chef-provisioning/issues/327)
- chef\_version convergence option is ignored for windows machines [\#300](https://github.com/chef/chef-provisioning/issues/300)
- Create opennebula plugin for chef-provisioning [\#264](https://github.com/chef/chef-provisioning/issues/264)

**Merged pull requests:**

- Remove warning about Hosted/Enterprise and clients in admins group [\#402](https://github.com/chef/chef-provisioning/pull/402) ([jkeiser](https://github.com/jkeiser))
- Add Travis badge to README. [\#400](https://github.com/chef/chef-provisioning/pull/400) ([randomcamel](https://github.com/randomcamel))
- Initial .travis.yml. [\#398](https://github.com/chef/chef-provisioning/pull/398) ([randomcamel](https://github.com/randomcamel))
- use mixlib-install to install from omnitruck [\#389](https://github.com/chef/chef-provisioning/pull/389) ([thommay](https://github.com/thommay))

## [v1.2.1](https://github.com/chef/chef-provisioning/tree/v1.2.1) (2015-07-17)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.2.0...v1.2.1)

**Fixed bugs:**

- Conflicting winrm gem causes knife to fail [\#370](https://github.com/chef/chef-provisioning/issues/370)
- remove or update test/acceptance project [\#363](https://github.com/chef/chef-provisioning/issues/363)
- Arity mismatch between MachineImage's :destroy and Driver\#destroy\_image [\#358](https://github.com/chef/chef-provisioning/issues/358)
- manual hydrate needed with chef\_data\_bag on create [\#242](https://github.com/chef/chef-provisioning/issues/242)
- ChefMetal::ConvergenceStrategy::PrecreateChefObjects does not support proxy settings [\#187](https://github.com/chef/chef-provisioning/issues/187)
- Suppress key\_data in debug output [\#171](https://github.com/chef/chef-provisioning/issues/171)
- host\_node being set to /organizations/NAME/nodes/ with no node name [\#141](https://github.com/chef/chef-provisioning/issues/141)
- Authorized ssh key overwritten with metal\_default [\#131](https://github.com/chef/chef-provisioning/issues/131)
- Deleting acceptance tests since they are super stale, fixes \#363 [\#379](https://github.com/chef/chef-provisioning/pull/379) ([tyler-ball](https://github.com/tyler-ball))
- Fix chef\_group [\#346](https://github.com/chef/chef-provisioning/pull/346) ([obazoud](https://github.com/obazoud))
- Add options\[:scp\_temp\_dir\] to set a SCP destination other than /tmp [\#339](https://github.com/chef/chef-provisioning/pull/339) ([glennmatthews](https://github.com/glennmatthews))

**Closed issues:**

- Lower the version of chef. [\#391](https://github.com/chef/chef-provisioning/issues/391)
- Cannot bootstrap FreeBSD \(bash is not installed\) [\#381](https://github.com/chef/chef-provisioning/issues/381)
- user\_data is not working in provisioning ec2 server [\#375](https://github.com/chef/chef-provisioning/issues/375)
- Latest provisioning gem is incompatible with semi-recent Chef [\#374](https://github.com/chef/chef-provisioning/issues/374)
- Chef Provisioning- Vagrant [\#373](https://github.com/chef/chef-provisioning/issues/373)
- Chef Provisioning- Vagrant  [\#367](https://github.com/chef/chef-provisioning/issues/367)
- unusual behavior w/ chef-client -z and provisioning [\#357](https://github.com/chef/chef-provisioning/issues/357)
- Merge Chef-maintained drivers into the chef-provisioning repo [\#354](https://github.com/chef/chef-provisioning/issues/354)
- Update to the SDK V2 [\#353](https://github.com/chef/chef-provisioning/issues/353)
- Add support for reserved instances [\#351](https://github.com/chef/chef-provisioning/issues/351)
- OpenSSL issue with chef provisioning [\#343](https://github.com/chef/chef-provisioning/issues/343)
- no implicit conversion of String into Integer [\#270](https://github.com/chef/chef-provisioning/issues/270)
-    The specified wait\_for timeout \(0.01 seconds\) was exceeded [\#269](https://github.com/chef/chef-provisioning/issues/269)
- Chef::Config.private\_key\_paths does not include ~/.chef/keys by default [\#258](https://github.com/chef/chef-provisioning/issues/258)
- chef-client -z can't find my ssh key when creating aws machine\_image [\#234](https://github.com/chef/chef-provisioning/issues/234)
- Document which classes are part of the public interface [\#203](https://github.com/chef/chef-provisioning/issues/203)
- machine\_batch failing on write file /etc/chef/client.pem [\#189](https://github.com/chef/chef-provisioning/issues/189)
- with\_driver fails on second converge: Canonical driver ... has already been created! [\#184](https://github.com/chef/chef-provisioning/issues/184)
- Output doesn't stream when run within non-login session. [\#176](https://github.com/chef/chef-provisioning/issues/176)
- QUESTION: How can I use a custom Chef library with Metal? [\#173](https://github.com/chef/chef-provisioning/issues/173)
- machine\_batch convergence cookbook synchronization very slow [\#172](https://github.com/chef/chef-provisioning/issues/172)

**Merged pull requests:**

- Tiny doc update to add clarity to vagrant provisioning example [\#369](https://github.com/chef/chef-provisioning/pull/369) ([scotthain](https://github.com/scotthain))
- Fix \#358: Arity mismatch [\#364](https://github.com/chef/chef-provisioning/pull/364) ([randomcamel](https://github.com/randomcamel))
- change chef-provisioning-fog to chef-provisioning-aws in the AWS example [\#352](https://github.com/chef/chef-provisioning/pull/352) ([metadave](https://github.com/metadave))
- update readme with vsphere driver url [\#344](https://github.com/chef/chef-provisioning/pull/344) ([mwrock](https://github.com/mwrock))

## [v1.2.0](https://github.com/chef/chef-provisioning/tree/v1.2.0) (2015-05-27)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.1.1...v1.2.0)

**Fixed bugs:**

- machine\_batch :destroy may be creating additional threads which result in NoMethodError [\#319](https://github.com/chef/chef-provisioning/issues/319)

**Closed issues:**

- chef-dk 0.5.1 with chef-zero renders unusable chefzero://localhost:8889 URLs on nodes [\#336](https://github.com/chef/chef-provisioning/issues/336)
- Updating chef-provisioning-aws breaks chef-client -z functionality with ChefDK 0.4.0 \(current version\). [\#322](https://github.com/chef/chef-provisioning/issues/322)
- Converging 0 resources - Am I missing something? [\#320](https://github.com/chef/chef-provisioning/issues/320)

**Merged pull requests:**

- with\_driver must be specified [\#345](https://github.com/chef/chef-provisioning/pull/345) ([jtimberman](https://github.com/jtimberman))
- Updating for newly introduced socketless mode [\#337](https://github.com/chef/chef-provisioning/pull/337) ([tyler-ball](https://github.com/tyler-ball))
- bumping winrm dependency to 1.3.0 [\#332](https://github.com/chef/chef-provisioning/pull/332) ([mwrock](https://github.com/mwrock))
- Adding documentation about the private key path [\#328](https://github.com/chef/chef-provisioning/pull/328) ([b-slim](https://github.com/b-slim))
- Update chef gem to fix version conflict in ChefDK [\#314](https://github.com/chef/chef-provisioning/pull/314) ([teknofire](https://github.com/teknofire))
- Update building\_drivers.md [\#309](https://github.com/chef/chef-provisioning/pull/309) ([jjasghar](https://github.com/jjasghar))

## [v1.1.1](https://github.com/chef/chef-provisioning/tree/v1.1.1) (2015-04-20)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.1.0...v1.1.1)

## [v1.1.0](https://github.com/chef/chef-provisioning/tree/v1.1.0) (2015-04-16)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.0.1...v1.1.0)

**Closed issues:**

- Net::HTTPServerException: 404 "Not Found" [\#323](https://github.com/chef/chef-provisioning/issues/323)

**Merged pull requests:**

- fix machine\_batch :destroy \#319 [\#321](https://github.com/chef/chef-provisioning/pull/321) ([wrightp](https://github.com/wrightp))
- Install chef-client using Proxy [\#317](https://github.com/chef/chef-provisioning/pull/317) ([afiune](https://github.com/afiune))
- Allow user to specify a custom stdout in Chef::Config\[:stdout\] [\#311](https://github.com/chef/chef-provisioning/pull/311) ([jkeiser](https://github.com/jkeiser))

## [v1.0.1](https://github.com/chef/chef-provisioning/tree/v1.0.1) (2015-04-07)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.0.0...v1.0.1)

**Closed issues:**

- Second run fails using Vagrant \(problem in InstallCached strategy\) [\#308](https://github.com/chef/chef-provisioning/issues/308)

**Merged pull requests:**

- Dependency cleanup [\#316](https://github.com/chef/chef-provisioning/pull/316) ([tyler-ball](https://github.com/tyler-ball))
- Delete machine specs when machines are deleted [\#310](https://github.com/chef/chef-provisioning/pull/310) ([jkeiser](https://github.com/jkeiser))

## [v1.0.0](https://github.com/chef/chef-provisioning/tree/v1.0.0) (2015-04-02)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.0.0.rc.2...v1.0.0)

## [v1.0.0.rc.2](https://github.com/chef/chef-provisioning/tree/v1.0.0.rc.2) (2015-04-02)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.20.1...v1.0.0.rc.2)

## [v0.20.1](https://github.com/chef/chef-provisioning/tree/v0.20.1) (2015-04-02)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v1.0.0.rc.1...v0.20.1)

## [v1.0.0.rc.1](https://github.com/chef/chef-provisioning/tree/v1.0.0.rc.1) (2015-04-01)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.20...v1.0.0.rc.1)

## [v0.20](https://github.com/chef/chef-provisioning/tree/v0.20) (2015-03-27)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.19...v0.20)

**Fixed bugs:**

- action :delete & action :destroy [\#186](https://github.com/chef/chef-provisioning/issues/186)
- support setting desired chef client version [\#148](https://github.com/chef/chef-provisioning/issues/148)
- Attributes are erased at re-converge when set in 'machine' resource [\#137](https://github.com/chef/chef-provisioning/issues/137)
- Machine\_batch converge action erases attributes created by recipes during the converge [\#116](https://github.com/chef/chef-provisioning/issues/116)
- Can't use Chef::Node::ImmutableMash in "attributes" attribute in the machine resource [\#21](https://github.com/chef/chef-provisioning/issues/21)

**Closed issues:**

- Can not destroy load balancers [\#307](https://github.com/chef/chef-provisioning/issues/307)
- machine\[\].create idempotency checks fails in freebsd [\#289](https://github.com/chef/chef-provisioning/issues/289)
- load\_balancer errors on :destroy action [\#278](https://github.com/chef/chef-provisioning/issues/278)
- machine\_execute seems not to have problems figuring out what driver to use? [\#201](https://github.com/chef/chef-provisioning/issues/201)

**Merged pull requests:**

- Use the actual `name` from the superclass, else we get caught in a loop [\#312](https://github.com/chef/chef-provisioning/pull/312) ([jkeiser](https://github.com/jkeiser))
- Jk/empty lb [\#299](https://github.com/chef/chef-provisioning/pull/299) ([jkeiser](https://github.com/jkeiser))
- Create generic "spec\_registry" which will allow drivers to [\#297](https://github.com/chef/chef-provisioning/pull/297) ([jkeiser](https://github.com/jkeiser))
- Make with\_driver do ... end work [\#296](https://github.com/chef/chef-provisioning/pull/296) ([jkeiser](https://github.com/jkeiser))

## [v0.19](https://github.com/chef/chef-provisioning/tree/v0.19) (2015-02-26)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.18...v0.19)

**Fixed bugs:**

- chef-metal is nuking 'normal' attributes on every converge. [\#209](https://github.com/chef/chef-provisioning/issues/209)
- Initial chef-client run on workstation talking to hosted chef-server fails on creating client [\#59](https://github.com/chef/chef-provisioning/issues/59)

**Closed issues:**

- machine\_batch does not inherit option from with\_machine\_options [\#277](https://github.com/chef/chef-provisioning/issues/277)
- There doesn't seem to be a way to define provider specific settings for Vagrant [\#271](https://github.com/chef/chef-provisioning/issues/271)
- with\_data\_center method does not work with chef-provisioning [\#265](https://github.com/chef/chef-provisioning/issues/265)
- NoMethodError: undefined method `gsub' for nil:NilClass following net-ssh patch upgrade [\#263](https://github.com/chef/chef-provisioning/issues/263)
- Stuck at ssh for centos aws machine [\#257](https://github.com/chef/chef-provisioning/issues/257)
- Broken link and update in Documentation [\#252](https://github.com/chef/chef-provisioning/issues/252)
- visibility for machine\_options issue [\#246](https://github.com/chef/chef-provisioning/issues/246)

**Merged pull requests:**

- Don't save after converge \(that destroys attributes created by the converge\) [\#294](https://github.com/chef/chef-provisioning/pull/294) ([jkeiser](https://github.com/jkeiser))
- Fix \#59: set node permissions correctly before converging [\#293](https://github.com/chef/chef-provisioning/pull/293) ([jkeiser](https://github.com/jkeiser))
- Remove some project noise files ;\) [\#291](https://github.com/chef/chef-provisioning/pull/291) ([fnichol](https://github.com/fnichol))
- Pass \[\] instead of nil when there are no machine specs [\#286](https://github.com/chef/chef-provisioning/pull/286) ([jkeiser](https://github.com/jkeiser))
- Add chef\_version, prerelease and install\_sh\_arguments to InstallSh [\#284](https://github.com/chef/chef-provisioning/pull/284) ([jkeiser](https://github.com/jkeiser))
- Add machine.chef\_config attribute to change client.rb [\#279](https://github.com/chef/chef-provisioning/pull/279) ([jkeiser](https://github.com/jkeiser))
- Usability updates for my first time using chef-provisioning [\#275](https://github.com/chef/chef-provisioning/pull/275) ([tyler-ball](https://github.com/tyler-ball))

## [v0.18](https://github.com/chef/chef-provisioning/tree/v0.18) (2015-01-27)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.17...v0.18)

**Fixed bugs:**

- Runlist...doesn't...? [\#249](https://github.com/chef/chef-provisioning/issues/249)

**Closed issues:**

- Cannot associate Elastic IP with EC2 driver to machine [\#253](https://github.com/chef/chef-provisioning/issues/253)

**Merged pull requests:**

- Fix forward\_port when using net-ssh 2.9.2. [\#267](https://github.com/chef/chef-provisioning/pull/267) ([causton81](https://github.com/causton81))
- Destroy action to the image provider. [\#251](https://github.com/chef/chef-provisioning/pull/251) ([miguelcnf](https://github.com/miguelcnf))

## [v0.17](https://github.com/chef/chef-provisioning/tree/v0.17) (2014-12-17)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.16...v0.17)

**Fixed bugs:**

- Automatically create images data bag if needed [\#228](https://github.com/chef/chef-provisioning/issues/228)
- Vagrant Example Fails with Checksum Mismatch [\#206](https://github.com/chef/chef-provisioning/issues/206)
- Stuck waiting for Windows SSH access? [\#144](https://github.com/chef/chef-provisioning/issues/144)

**Closed issues:**

- error running the example  [\#231](https://github.com/chef/chef-provisioning/issues/231)
- machine\_batch doesn't destroy [\#226](https://github.com/chef/chef-provisioning/issues/226)
- README shows incorrect require for using fog\_key\_pair [\#225](https://github.com/chef/chef-provisioning/issues/225)
- Error: Could not find a valid gem 'chef-provisioning-vagrant' [\#217](https://github.com/chef/chef-provisioning/issues/217)
- signal to generate a key raises errors in converge output [\#213](https://github.com/chef/chef-provisioning/issues/213)
- Machine destroy fails with "undefined local variable or method `iam\_endpoint'" [\#198](https://github.com/chef/chef-provisioning/issues/198)
- FAQ link in readme leads to 404 [\#192](https://github.com/chef/chef-provisioning/issues/192)
- Windows converge error: command 'mkdir -p /etc/chef' exited with code 127 [\#178](https://github.com/chef/chef-provisioning/issues/178)
- Way to not need an /etc/chef for provisioning chef-client run? [\#177](https://github.com/chef/chef-provisioning/issues/177)
- Error executing action 'destroy' on resource 'machine\_batch\[default\]' [\#152](https://github.com/chef/chef-provisioning/issues/152)
- Setting up local mode when embedding chef-metal [\#85](https://github.com/chef/chef-provisioning/issues/85)

**Merged pull requests:**

- Remove pry [\#248](https://github.com/chef/chef-provisioning/pull/248) ([jaym](https://github.com/jaym))
- Update to ignore .idea directories. [\#247](https://github.com/chef/chef-provisioning/pull/247) ([miguelcnf](https://github.com/miguelcnf))
- Change Metal to Provisioning [\#240](https://github.com/chef/chef-provisioning/pull/240) ([twellspring](https://github.com/twellspring))
- In simple example, require chef/provisioning [\#239](https://github.com/chef/chef-provisioning/pull/239) ([janeireton](https://github.com/janeireton))
- MEGA chef-provisioning-test-suite project dump [\#238](https://github.com/chef/chef-provisioning/pull/238) ([wrightp](https://github.com/wrightp))
- Fix ssh driver url [\#233](https://github.com/chef/chef-provisioning/pull/233) ([gravitystorm](https://github.com/gravitystorm))
- Flip logic on ssl peer validation [\#232](https://github.com/chef/chef-provisioning/pull/232) ([andrewelizondo](https://github.com/andrewelizondo))
- add chef-provisioning-crowbar to README.md [\#230](https://github.com/chef/chef-provisioning/pull/230) ([newgoliath](https://github.com/newgoliath))
- Update vSphere driver link. [\#229](https://github.com/chef/chef-provisioning/pull/229) ([cmluciano](https://github.com/cmluciano))
- Make machine\_batch convergent [\#227](https://github.com/chef/chef-provisioning/pull/227) ([jkeiser](https://github.com/jkeiser))
- Work with Chef 12 [\#224](https://github.com/chef/chef-provisioning/pull/224) ([jkeiser](https://github.com/jkeiser))

## [v0.16](https://github.com/chef/chef-provisioning/tree/v0.16) (2014-11-05)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.15.3...v0.16)

## [v0.15.3](https://github.com/chef/chef-provisioning/tree/v0.15.3) (2014-11-05)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.15.2...v0.15.3)

## [v0.15.2](https://github.com/chef/chef-provisioning/tree/v0.15.2) (2014-11-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.15.1...v0.15.2)

**Closed issues:**

- config validation [\#223](https://github.com/chef/chef-provisioning/issues/223)
- create utility for generating chef-client command strings based on server, driver, platform, tests, etc [\#222](https://github.com/chef/chef-provisioning/issues/222)
- configurable os platform/version and mapping [\#221](https://github.com/chef/chef-provisioning/issues/221)
- chef-client error scanning [\#220](https://github.com/chef/chef-provisioning/issues/220)
- add azure driver test [\#219](https://github.com/chef/chef-provisioning/issues/219)
- Configure chef-provisioning-test-suite for Travis CI [\#218](https://github.com/chef/chef-provisioning/issues/218)
- Doubt in Server Provisioning through Chef metal, Vagrant and VBox [\#215](https://github.com/chef/chef-provisioning/issues/215)
- Where is chef-provisioning-fog? [\#214](https://github.com/chef/chef-provisioning/issues/214)

**Merged pull requests:**

- Rename Chef Metal to Chef Provisioning [\#216](https://github.com/chef/chef-provisioning/pull/216) ([kanerogers](https://github.com/kanerogers))

## [v0.15.1](https://github.com/chef/chef-provisioning/tree/v0.15.1) (2014-10-30)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.15...v0.15.1)

**Closed issues:**

- Rename to chef-provisioning [\#210](https://github.com/chef/chef-provisioning/issues/210)

## [v0.15](https://github.com/chef/chef-provisioning/tree/v0.15) (2014-10-29)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.14.2...v0.15)

**Fixed bugs:**

- machine.tag does not add tag to AWS \(only the node\) [\#165](https://github.com/chef/chef-provisioning/issues/165)
- with\_chef\_local\_server isn't working with metal 0.14.2 [\#159](https://github.com/chef/chef-provisioning/issues/159)
- Remove default parallelism [\#124](https://github.com/chef/chef-provisioning/issues/124)
- Server provesioning through Vagrant behind Corporate Firewall using Chef Metal. [\#121](https://github.com/chef/chef-provisioning/issues/121)
- machine\_file connects as vagrant  [\#120](https://github.com/chef/chef-provisioning/issues/120)
- 'action :converge\_only' exception [\#90](https://github.com/chef/chef-provisioning/issues/90)
- Unable to use Vagrant driver behind corporate http proxy [\#74](https://github.com/chef/chef-provisioning/issues/74)

**Closed issues:**

- FFI\_Yajl::ParseError: parse error: premature EOF when using with\_chef\_server [\#204](https://github.com/chef/chef-provisioning/issues/204)
- Azure Support [\#191](https://github.com/chef/chef-provisioning/issues/191)
- QUESTION: Multiple machine tags [\#188](https://github.com/chef/chef-provisioning/issues/188)
- ChecksumMismatch error running example with Vagrant provider [\#183](https://github.com/chef/chef-provisioning/issues/183)
- Can I send user data to AWS when creating an instance from an AMI [\#182](https://github.com/chef/chef-provisioning/issues/182)
- Net::HTTPServerException: 404 "Object Not Found" [\#181](https://github.com/chef/chef-provisioning/issues/181)
- undefined method `\<\<' for \#\<Chef::EventDispatch::EventsOutputStream:0x00000005431890\> [\#179](https://github.com/chef/chef-provisioning/issues/179)
- Can't connect to Windows machine running SSH [\#175](https://github.com/chef/chef-provisioning/issues/175)
- custom bootstrap? [\#169](https://github.com/chef/chef-provisioning/issues/169)
- Is the -j option working correctly with metal? [\#168](https://github.com/chef/chef-provisioning/issues/168)
- Can I run more than one chef-client at once? [\#166](https://github.com/chef/chef-provisioning/issues/166)
- with\_chef\_local\_server can't find vendored cookbook [\#163](https://github.com/chef/chef-provisioning/issues/163)
- Not handling metadata.rb dependencies correctly? [\#161](https://github.com/chef/chef-provisioning/issues/161)
- with\_chef\_local\_server can't find cookbook in cookbook\_path [\#160](https://github.com/chef/chef-provisioning/issues/160)
- Converging after creating - undefined method 'split' for nil:NilClass [\#158](https://github.com/chef/chef-provisioning/issues/158)
- Provisioning machines at a later time after creating [\#156](https://github.com/chef/chef-provisioning/issues/156)
- Convergence error - Permission denied @ dir\_s\_mkdir [\#154](https://github.com/chef/chef-provisioning/issues/154)
- Annoying SSL warning when creating new machine [\#150](https://github.com/chef/chef-provisioning/issues/150)
- "SSH did not come up" timeout [\#146](https://github.com/chef/chef-provisioning/issues/146)
- Proxy blocking installations. [\#145](https://github.com/chef/chef-provisioning/issues/145)
- Chef-metal-fog with digital ocean doesn't seem to like large ssh keys [\#140](https://github.com/chef/chef-provisioning/issues/140)

**Merged pull requests:**

- Chef provisioning [\#211](https://github.com/chef/chef-provisioning/pull/211) ([jkeiser](https://github.com/jkeiser))
- Require data bag resources [\#208](https://github.com/chef/chef-provisioning/pull/208) ([raskchanky](https://github.com/raskchanky))
- Support for resources that are backed by data bags [\#205](https://github.com/chef/chef-provisioning/pull/205) ([johnewart](https://github.com/johnewart))
- Add a Gitter chat badge to README.md [\#199](https://github.com/chef/chef-provisioning/pull/199) ([gitter-badger](https://github.com/gitter-badger))
- Load balancer and data center support work [\#196](https://github.com/chef/chef-provisioning/pull/196) ([johnewart](https://github.com/johnewart))
- Makes it so that a user who has sudo permissions can download a file that their user wouldn't have permission to access normally. [\#195](https://github.com/chef/chef-provisioning/pull/195) ([johnewart](https://github.com/johnewart))
- Winrm bump [\#194](https://github.com/chef/chef-provisioning/pull/194) ([mwrock](https://github.com/mwrock))
- YARDoc updates [\#193](https://github.com/chef/chef-provisioning/pull/193) ([johnewart](https://github.com/johnewart))
- do not verify ssl because we only use http [\#164](https://github.com/chef/chef-provisioning/pull/164) ([hh](https://github.com/hh))
- Added proxy support for metadata download [\#162](https://github.com/chef/chef-provisioning/pull/162) ([ndobson](https://github.com/ndobson))

## [v0.14.2](https://github.com/chef/chef-provisioning/tree/v0.14.2) (2014-09-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.14.1...v0.14.2)

**Fixed bugs:**

- Some node names don't seem to work \(car and sun\) [\#129](https://github.com/chef/chef-provisioning/issues/129)
- NoMethodError - machine\[central-server-1\] \(centralized\_repository::default line 63\) had an error: NoMethodError: undefined method `name' for \["BootstrapHost", "myhostname"\]:Array [\#114](https://github.com/chef/chef-provisioning/issues/114)
- Error on machine\_batch if running chef as different user [\#111](https://github.com/chef/chef-provisioning/issues/111)
- Chef 11.12.8 incompatible with cheffish 0.7 [\#106](https://github.com/chef/chef-provisioning/issues/106)
- with\_machine\_options does not honor :key\_name [\#91](https://github.com/chef/chef-provisioning/issues/91)
- nil machine object raise expection in dry-run [\#54](https://github.com/chef/chef-provisioning/issues/54)
- After creating the node/client ec2 attributes are not available [\#34](https://github.com/chef/chef-provisioning/issues/34)
- 'with\_chef\_server' bootstrap permissions for client.pem and client.rb [\#32](https://github.com/chef/chef-provisioning/issues/32)

**Closed issues:**

- Possible to use different ports for parallel chef-zero runs? [\#155](https://github.com/chef/chef-provisioning/issues/155)
- SCP did not finish successfully \(1\) [\#151](https://github.com/chef/chef-provisioning/issues/151)
- cannot load such file -- chef\_metal/driver\_init/fog [\#149](https://github.com/chef/chef-provisioning/issues/149)
- Chef::Exceptions::ContentLengthMismatch: Response body length 65536 does not match HTTP Content-Length header 88744. [\#139](https://github.com/chef/chef-provisioning/issues/139)
- Dependency solver overloaded [\#112](https://github.com/chef/chef-provisioning/issues/112)
- 0.13 issue: Unable to resolve dependencies: cheffish requires chef-zero \(~\> 2.2\) [\#105](https://github.com/chef/chef-provisioning/issues/105)

**Merged pull requests:**

- pass timeout from execution\_options to winrm set\_timeout [\#153](https://github.com/chef/chef-provisioning/pull/153) ([mwrock](https://github.com/mwrock))
- Remove Chef 11.14 alpha note in readme [\#136](https://github.com/chef/chef-provisioning/pull/136) ([viglesiasce](https://github.com/viglesiasce))
- Handle Host Down and Network Unreachable [\#127](https://github.com/chef/chef-provisioning/pull/127) ([viglesiasce](https://github.com/viglesiasce))

## [v0.14.1](https://github.com/chef/chef-provisioning/tree/v0.14.1) (2014-08-19)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.14...v0.14.1)

**Closed issues:**

- perform convergence talking to chef-zero on the node \(ala test-kitchen\) [\#122](https://github.com/chef/chef-provisioning/issues/122)

## [v0.14](https://github.com/chef/chef-provisioning/tree/v0.14) (2014-08-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.13...v0.14)

**Closed issues:**

- Creating clusters in Vagrant with chef-metal yields a Net::SSH::Exception [\#123](https://github.com/chef/chef-provisioning/issues/123)
- Error running Vagrant example on Windows 7 [\#118](https://github.com/chef/chef-provisioning/issues/118)
- Make an image factory [\#109](https://github.com/chef/chef-provisioning/issues/109)

**Merged pull requests:**

- Get machine images working with multiple machines [\#119](https://github.com/chef/chef-provisioning/pull/119) ([johnewart](https://github.com/johnewart))
- add VPC related comments to docs for AWS provider [\#117](https://github.com/chef/chef-provisioning/pull/117) ([andrewgoktepe](https://github.com/andrewgoktepe))
- Machine image fixes [\#113](https://github.com/chef/chef-provisioning/pull/113) ([johnewart](https://github.com/johnewart))
- Machine image [\#110](https://github.com/chef/chef-provisioning/pull/110) ([jkeiser](https://github.com/jkeiser))

## [v0.13](https://github.com/chef/chef-provisioning/tree/v0.13) (2014-07-15)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.7.1...v0.13)

## [v0.7.1](https://github.com/chef/chef-provisioning/tree/v0.7.1) (2014-07-15)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.6.1...v0.7.1)

**Fixed bugs:**

- Are there plans to make the fog gem an "opt in"? [\#63](https://github.com/chef/chef-provisioning/issues/63)

**Closed issues:**

- undefined method `parallel\_do' [\#101](https://github.com/chef/chef-provisioning/issues/101)
- Bootstrapping Windows against chef-zero [\#96](https://github.com/chef/chef-provisioning/issues/96)
- Changing the runlist of a machine [\#95](https://github.com/chef/chef-provisioning/issues/95)
- Allow for indirect connectivity to nodes in driver interface [\#93](https://github.com/chef/chef-provisioning/issues/93)

**Merged pull requests:**

- add docs for providers [\#104](https://github.com/chef/chef-provisioning/pull/104) ([MrMMorris](https://github.com/MrMMorris))
- Add workaround for Hosted Chef servers to README [\#103](https://github.com/chef/chef-provisioning/pull/103) ([MrMMorris](https://github.com/MrMMorris))
- include bootstrap\_proxy key into convergence\_options [\#102](https://github.com/chef/chef-provisioning/pull/102) ([SIGUSR2](https://github.com/SIGUSR2))
- winrm fixes [\#100](https://github.com/chef/chef-provisioning/pull/100) ([mwrock](https://github.com/mwrock))
- waffle.io Badge [\#92](https://github.com/chef/chef-provisioning/pull/92) ([waffle-iron](https://github.com/waffle-iron))

## [v0.6.1](https://github.com/chef/chef-provisioning/tree/v0.6.1) (2014-06-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.12.1...v0.6.1)

## [v0.12.1](https://github.com/chef/chef-provisioning/tree/v0.12.1) (2014-06-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.12...v0.12.1)

**Closed issues:**

- Failure with action :setup and machine\_batch [\#83](https://github.com/chef/chef-provisioning/issues/83)

## [v0.12](https://github.com/chef/chef-provisioning/tree/v0.12) (2014-06-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.4...v0.12)

**Closed issues:**

- Less SSH Trash output [\#87](https://github.com/chef/chef-provisioning/issues/87)
- 403 error when registering the new node as a client [\#80](https://github.com/chef/chef-provisioning/issues/80)

**Merged pull requests:**

- Fix incorrect timeline/blog post date in README.md [\#86](https://github.com/chef/chef-provisioning/pull/86) ([mikedillion](https://github.com/mikedillion))

## [v0.5.4](https://github.com/chef/chef-provisioning/tree/v0.5.4) (2014-06-10)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.3...v0.5.4)

**Merged pull requests:**

- Typo fix in README [\#84](https://github.com/chef/chef-provisioning/pull/84) ([jalessio](https://github.com/jalessio))
- fixing ssl verify mode value from none to verify\_none [\#82](https://github.com/chef/chef-provisioning/pull/82) ([mwrock](https://github.com/mwrock))
- Fix machine\_file and machine\_execute which depend on connect\_to\_machine ... [\#81](https://github.com/chef/chef-provisioning/pull/81) ([irvingpop](https://github.com/irvingpop))

## [v0.5.3](https://github.com/chef/chef-provisioning/tree/v0.5.3) (2014-06-05)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.2...v0.5.3)

## [v0.11.2](https://github.com/chef/chef-provisioning/tree/v0.11.2) (2014-06-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.2...v0.11.2)

## [v0.5.2](https://github.com/chef/chef-provisioning/tree/v0.5.2) (2014-06-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.1...v0.5.2)

**Fixed bugs:**

- Non-Ubuntu AWS SSH Does not work [\#69](https://github.com/chef/chef-provisioning/issues/69)

**Closed issues:**

- with\_chef\_local\_server :port gets you two listening chef-zero instances [\#79](https://github.com/chef/chef-provisioning/issues/79)

## [v0.11.1](https://github.com/chef/chef-provisioning/tree/v0.11.1) (2014-06-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.1...v0.11.1)

**Closed issues:**

- ERROR: undefined method `config\_for\_url' for ChefMetal:Module [\#73](https://github.com/chef/chef-provisioning/issues/73)

## [v0.5.1](https://github.com/chef/chef-provisioning/tree/v0.5.1) (2014-06-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11...v0.5.1)

## [v0.11](https://github.com/chef/chef-provisioning/tree/v0.11) (2014-06-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.11...v0.11)

**Closed issues:**

- Add '--config-file-jail .' to the example given where you first spin up a box. [\#77](https://github.com/chef/chef-provisioning/issues/77)
- dependency chef-metal-vagrant [\#76](https://github.com/chef/chef-provisioning/issues/76)
- provisioner\_options not valid anymore? [\#75](https://github.com/chef/chef-provisioning/issues/75)

## [v0.11.beta.11](https://github.com/chef/chef-provisioning/tree/v0.11.beta.11) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta.6...v0.11.beta.11)

## [v0.5.beta.6](https://github.com/chef/chef-provisioning/tree/v0.5.beta.6) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.10...v0.5.beta.6)

## [v0.11.beta.10](https://github.com/chef/chef-provisioning/tree/v0.11.beta.10) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta.5...v0.11.beta.10)

## [v0.5.beta.5](https://github.com/chef/chef-provisioning/tree/v0.5.beta.5) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.9...v0.5.beta.5)

## [v0.11.beta.9](https://github.com/chef/chef-provisioning/tree/v0.11.beta.9) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.8...v0.11.beta.9)

## [v0.11.beta.8](https://github.com/chef/chef-provisioning/tree/v0.11.beta.8) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta.4...v0.11.beta.8)

## [v0.5.beta.4](https://github.com/chef/chef-provisioning/tree/v0.5.beta.4) (2014-06-03)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.7...v0.5.beta.4)

**Closed issues:**

- Documentation of Using Chef Profiles: bug or feature? [\#72](https://github.com/chef/chef-provisioning/issues/72)
- chefspec tests see machines as machine\_batch [\#66](https://github.com/chef/chef-provisioning/issues/66)
- Machines are converging twice [\#62](https://github.com/chef/chef-provisioning/issues/62)
- How can i use 'secret\_file' from workstation knife config [\#33](https://github.com/chef/chef-provisioning/issues/33)
- Question: Is there an example for 'with\_chef\_server' [\#13](https://github.com/chef/chef-provisioning/issues/13)
- Consider using the newer lxc-download template [\#12](https://github.com/chef/chef-provisioning/issues/12)
- Any reasons this is packaged as a gem and not HWRPs? [\#9](https://github.com/chef/chef-provisioning/issues/9)
- Does chef-metal currently support Openstack? [\#5](https://github.com/chef/chef-provisioning/issues/5)
- provisioner\_option directive overwrites defaults [\#3](https://github.com/chef/chef-provisioning/issues/3)

## [v0.11.beta.7](https://github.com/chef/chef-provisioning/tree/v0.11.beta.7) (2014-05-31)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta.3...v0.11.beta.7)

## [v0.5.beta.3](https://github.com/chef/chef-provisioning/tree/v0.5.beta.3) (2014-05-31)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.6...v0.5.beta.3)

**Closed issues:**

- Problems with with\_chef\_server [\#67](https://github.com/chef/chef-provisioning/issues/67)

## [v0.11.beta.6](https://github.com/chef/chef-provisioning/tree/v0.11.beta.6) (2014-05-29)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.5...v0.11.beta.6)

**Closed issues:**

- The run list from machine resource is not saved on node. [\#35](https://github.com/chef/chef-provisioning/issues/35)

**Merged pull requests:**

- Add options argument to SSH gateway [\#60](https://github.com/chef/chef-provisioning/pull/60) ([marcusn](https://github.com/marcusn))

## [v0.11.beta.5](https://github.com/chef/chef-provisioning/tree/v0.11.beta.5) (2014-05-28)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.4...v0.11.beta.5)

## [v0.11.beta.4](https://github.com/chef/chef-provisioning/tree/v0.11.beta.4) (2014-05-28)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta.2...v0.11.beta.4)

## [v0.5.beta.2](https://github.com/chef/chef-provisioning/tree/v0.5.beta.2) (2014-05-28)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.3...v0.5.beta.2)

## [v0.11.beta.3](https://github.com/chef/chef-provisioning/tree/v0.11.beta.3) (2014-05-28)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta.2...v0.11.beta.3)

**Merged pull requests:**

- typo editing [\#58](https://github.com/chef/chef-provisioning/pull/58) ([bdupras](https://github.com/bdupras))
- vmware typos [\#57](https://github.com/chef/chef-provisioning/pull/57) ([bdupras](https://github.com/bdupras))

## [v0.11.beta.2](https://github.com/chef/chef-provisioning/tree/v0.11.beta.2) (2014-05-24)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.11.beta...v0.11.beta.2)

## [v0.11.beta](https://github.com/chef/chef-provisioning/tree/v0.11.beta) (2014-05-23)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5.beta...v0.11.beta)

## [v0.5.beta](https://github.com/chef/chef-provisioning/tree/v0.5.beta) (2014-05-23)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.10.2...v0.5.beta)

**Closed issues:**

- SoftLayer provisioning options? [\#56](https://github.com/chef/chef-provisioning/issues/56)
- Error executing action `converge` on resource 'machine\_batch\[default\]' : Name Required [\#52](https://github.com/chef/chef-provisioning/issues/52)
- New nodes don't have permissions to update themselves [\#11](https://github.com/chef/chef-provisioning/issues/11)

**Merged pull requests:**

- Grant Transport support for ssh\_gateway used with jump hosts [\#53](https://github.com/chef/chef-provisioning/pull/53) ([JonathanSerafini](https://github.com/JonathanSerafini))

## [v0.10.2](https://github.com/chef/chef-provisioning/tree/v0.10.2) (2014-05-02)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.10.1...v0.10.2)

## [v0.10.1](https://github.com/chef/chef-provisioning/tree/v0.10.1) (2014-05-02)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.10...v0.10.1)

**Closed issues:**

- Error executing action `converge` on resource 'machine\_batch\[default\]' [\#51](https://github.com/chef/chef-provisioning/issues/51)

## [v0.10](https://github.com/chef/chef-provisioning/tree/v0.10) (2014-05-01)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.9.4...v0.10)

**Merged pull requests:**

- Update gem dependencies to use refactored chef\_metal\_fog [\#50](https://github.com/chef/chef-provisioning/pull/50) ([mikesplain](https://github.com/mikesplain))
- re-raise Net::SCP error when fails to download [\#49](https://github.com/chef/chef-provisioning/pull/49) ([carltonstedman](https://github.com/carltonstedman))

## [v0.9.4](https://github.com/chef/chef-provisioning/tree/v0.9.4) (2014-04-24)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.9.3...v0.9.4)

## [v0.9.3](https://github.com/chef/chef-provisioning/tree/v0.9.3) (2014-04-14)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.9.2...v0.9.3)

## [v0.9.2](https://github.com/chef/chef-provisioning/tree/v0.9.2) (2014-04-13)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.9.1...v0.9.2)

## [v0.9.1](https://github.com/chef/chef-provisioning/tree/v0.9.1) (2014-04-12)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.9...v0.9.1)

**Closed issues:**

- machine converge action fails with chef-zero [\#47](https://github.com/chef/chef-provisioning/issues/47)

## [v0.9](https://github.com/chef/chef-provisioning/tree/v0.9) (2014-04-11)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.8.2...v0.9)

**Closed issues:**

- Support for already-provisioned machines - enhancement request [\#41](https://github.com/chef/chef-provisioning/issues/41)

**Merged pull requests:**

- Apply the same fix from machine\_file to machine\_execute [\#48](https://github.com/chef/chef-provisioning/pull/48) ([irvingpop](https://github.com/irvingpop))

## [v0.8.2](https://github.com/chef/chef-provisioning/tree/v0.8.2) (2014-04-09)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.8.1...v0.8.2)

## [v0.8.1](https://github.com/chef/chef-provisioning/tree/v0.8.1) (2014-04-09)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.8...v0.8.1)

**Closed issues:**

- show machine chef-client run output - enhancement request [\#40](https://github.com/chef/chef-provisioning/issues/40)

**Merged pull requests:**

- New ohai hints feature allowing the creation hints. [\#38](https://github.com/chef/chef-provisioning/pull/38) ([ligature](https://github.com/ligature))

## [v0.8](https://github.com/chef/chef-provisioning/tree/v0.8) (2014-04-08)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.7...v0.8)

**Closed issues:**

- machine\_file enhancement\(s\) request [\#39](https://github.com/chef/chef-provisioning/issues/39)

**Merged pull requests:**

- Add a SUPER SIMPLE machine\_execute resource [\#46](https://github.com/chef/chef-provisioning/pull/46) ([irvingpop](https://github.com/irvingpop))

## [v0.7](https://github.com/chef/chef-provisioning/tree/v0.7) (2014-04-06)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.6...v0.7)

**Merged pull requests:**

- cookbooks should have their name in metadata [\#45](https://github.com/chef/chef-provisioning/pull/45) ([jtimberman](https://github.com/jtimberman))

## [v0.6](https://github.com/chef/chef-provisioning/tree/v0.6) (2014-04-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.5...v0.6)

**Merged pull requests:**

- Grant the node's client read+update permissions [\#44](https://github.com/chef/chef-provisioning/pull/44) ([dafyddcrosby](https://github.com/dafyddcrosby))

## [v0.5](https://github.com/chef/chef-provisioning/tree/v0.5) (2014-04-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.4...v0.5)

**Closed issues:**

- machine\_file :download fails because provider is undefined [\#42](https://github.com/chef/chef-provisioning/issues/42)

**Merged pull requests:**

- Add owner, group and mode attributes to machine\_file [\#43](https://github.com/chef/chef-provisioning/pull/43) ([irvingpop](https://github.com/irvingpop))
- Dt/driver surgery [\#36](https://github.com/chef/chef-provisioning/pull/36) ([jkeiser](https://github.com/jkeiser))
- Ec2 fixes [\#27](https://github.com/chef/chef-provisioning/pull/27) ([ligature](https://github.com/ligature))

## [v0.4](https://github.com/chef/chef-provisioning/tree/v0.4) (2014-03-29)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.3.1...v0.4)

**Closed issues:**

- Minimum fog version suggestion \('ubuntu' user hardcoded in AWS SSH\) [\#28](https://github.com/chef/chef-provisioning/issues/28)
- fog\_provisioner hardcoded to public\_ip\_address [\#20](https://github.com/chef/chef-provisioning/issues/20)
- ec2 availability\_zone ignored [\#19](https://github.com/chef/chef-provisioning/issues/19)

**Merged pull requests:**

- Show how to use with\_chef\_server using chef-client -z [\#37](https://github.com/chef/chef-provisioning/pull/37) ([dafyddcrosby](https://github.com/dafyddcrosby))
- Fix typo 'pey-pair-name' -\> 'key-pair-name' [\#30](https://github.com/chef/chef-provisioning/pull/30) ([dafyddcrosby](https://github.com/dafyddcrosby))
- Remove unused variable provisioner\_options [\#26](https://github.com/chef/chef-provisioning/pull/26) ([dafyddcrosby](https://github.com/dafyddcrosby))
- Update README.md to show how to add per-machine provisioner options [\#25](https://github.com/chef/chef-provisioning/pull/25) ([dafyddcrosby](https://github.com/dafyddcrosby))
- Added new private\_ip compute\_options attribute. [\#23](https://github.com/chef/chef-provisioning/pull/23) ([ligature](https://github.com/ligature))
- double double escape escape to fix RHEL/CentOS platform\_version detection [\#22](https://github.com/chef/chef-provisioning/pull/22) ([irvingpop](https://github.com/irvingpop))
- Initial Openstack support [\#15](https://github.com/chef/chef-provisioning/pull/15) ([cstewart87](https://github.com/cstewart87))

## [v0.3.1](https://github.com/chef/chef-provisioning/tree/v0.3.1) (2014-03-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.3...v0.3.1)

**Closed issues:**

- undefined method `synchronize' for nil:NilClass [\#18](https://github.com/chef/chef-provisioning/issues/18)

**Merged pull requests:**

- initialize right mutex. use ssl if required [\#17](https://github.com/chef/chef-provisioning/pull/17) ([ranjib](https://github.com/ranjib))
- Fix to\_sym error parsing bootstrap\_options [\#16](https://github.com/chef/chef-provisioning/pull/16) ([RoboticCheese](https://github.com/RoboticCheese))

## [v0.3](https://github.com/chef/chef-provisioning/tree/v0.3) (2014-03-18)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.2.1...v0.3)

**Closed issues:**

- Syntax for specifying flavor/image? [\#10](https://github.com/chef/chef-provisioning/issues/10)

**Merged pull requests:**

- Fix copypaste typo from vagrant to ec2 [\#14](https://github.com/chef/chef-provisioning/pull/14) ([dafyddcrosby](https://github.com/dafyddcrosby))

## [v0.2.1](https://github.com/chef/chef-provisioning/tree/v0.2.1) (2014-03-07)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.2...v0.2.1)

## [v0.2](https://github.com/chef/chef-provisioning/tree/v0.2) (2014-03-04)
[Full Changelog](https://github.com/chef/chef-provisioning/compare/v0.1...v0.2)

**Merged pull requests:**

- Update URLs of GH repo [\#8](https://github.com/chef/chef-provisioning/pull/8) ([StephenKing](https://github.com/StephenKing))
- Typo in README.md [\#7](https://github.com/chef/chef-provisioning/pull/7) ([StephenKing](https://github.com/StephenKing))
- support for lxc [\#6](https://github.com/chef/chef-provisioning/pull/6) ([ranjib](https://github.com/ranjib))
- Requirements [\#4](https://github.com/chef/chef-provisioning/pull/4) ([jkeiser](https://github.com/jkeiser))

## [v0.1](https://github.com/chef/chef-provisioning/tree/v0.1) (2013-12-21)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*