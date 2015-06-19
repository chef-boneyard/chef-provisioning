# vCloud Air Provider   

Connectivity to your vCloud Air API endpoint and connectivity to the network the nodes are created on is required and is usually not enabled by default.
It it also required that your nodes be able to download chef-client and reach your chef-server.

## known issues:

* ssh authentication happens via ssh and public_key is not available in initial images
* Only CentOS64-64Bit images currently function, Ubuntu, CentOS63-* and 32BIT versions do not set passwords correctly

## machine_options /  :ssh_options

Setting the password is required as inital ssh key authentication is not available in vCloud Air.

### :auth_methods

Must be set to ```[ 'password' ]```

### :password

Set to something random and secure.

### :user_known_hosts_file

Set to ```/dev/null``` as we have no way to retrieve the ssh-host fingerprint before connecting.

## machine_options / :bootstrap_options   

### :memory

in megabytes

### :cpus

count of virtual cpus

###  :use_private_ip_for_ssh

Necessary to find the right ip

### :image_name

```
$ knife vcair image list
Name                                      Description                            
C63x86_vCloudAir                          Application ready template             
CentOS63-32BIT                            id: cts-6.3-32bit                      
CentOS63-64BIT                            id: cts-6.3-64bit                      
CentOS64-32BIT                            id: cts-6.4-32bit                      
CentOS64-64BIT                            id: cts-6.4-64bit                      
Ubuntu Server 12.04 LTS (amd64 20150127)  id: UBUNTU1204-AMD-64BIT               
Ubuntu Server 12.04 LTS (i386 20150127)   id: UBUNTU1204-I386-64BIT              
W2K12-STD-64BIT                           id: W2K12-STD-64BIT                    
W2K12-STD-64BIT-SQL2K12-STD-SP1           id: W2K12-STD-64BIT-SQL2K12-STD-SP1    
W2K12-STD-64BIT-SQL2K12-WEB-SP1           id: W2K12-STD-64BIT-SQL2K12-WEB-SP1    
W2K12-STD-R2-64BIT                        id: W2K12-STD-R2-64BIT                 
W2K12-STD-R2-SQL2K14-STD                  id: W2K12-STD-R2-SQL2K14-STD           
W2K12-STD-R2-SQL2K14-WEB                  id: W2K12-STD-R2-SQL2K14-WEB           
W2K8-STD-R2-64BIT                         id: W2K8-STD-R2-64BIT                  
W2K8-STD-R2-64BIT-SQL2K8-STD-R2-SP2       id: W2K8-STD-R2-64BIT-SQL2K8-STD-R2-SP2
W2K8-STD-R2-64BIT-SQL2K8-WEB-R2-SP2       id: W2K8-STD-R2-64BIT-SQL2K8-WEB-R2-SP2
```

#### :net

```
$ knife vcair network list                                                                                                                                                   
Name                              Gateway        IP Range Start  End              Description                                       
M511664989-4904-default-isolated  192.168.99.1   192.168.99.2    192.168.99.100   This isolated network was created with Create VDC.
M511664989-4904-default-routed    192.168.109.1  192.168.109.2   192.168.109.100  This routed network was created with Create VDC.  
```

## linux vm video walkthru

* 0:10 [knife.rb options](https://youtu.be/js9R-ebjV7g?t=10)
* 0:30 [vmwaredemo.rb chef-provisioning recipe](https://youtu.be/js9R-ebjV7g?t=30)
* 1:18 [chef-client -z .../vmwaredemo.prb](https://youtu.be/js9R-ebjV7g?t=78)
* 1:58 [VMWare vCloud Air UI glimpse of app1 instance creation](https://youtu.be/js9R-ebjV7g?t=118)
* 2:33 [machine_options and provisioning app1 resource walk-thru](https://youtu.be/js9R-ebjV7g?t=153)
* 3:09 [vCloud Air UI verification of app1 instance](https://youtu.be/js9R-ebjV7g?t=189)
* 3:49 [app1 instance available via ssh](https://youtu.be/js9R-ebjV7g?t=229)
* 4:25 [Chef install started on app1](https://youtu.be/js9R-ebjV7g?t=265)
* 4:42 [Chef client started on app1](https://youtu.be/js9R-ebjV7g?t=282)
* 5:25 [vCloud Air UI verification db1 instance](https://youtu.be/js9R-ebjV7g?t=325)
* 5:42 [machine_options and provisioning db1 resource walk-thru](https://youtu.be/js9R-ebjV7g?t=342)
* 7:55 [db1 instance available via ssh 4gb mem, 2 cores](https://youtu.be/js9R-ebjV7g?t=475)
* 8:18 [Chef client started on db1](https://youtu.be/js9R-ebjV7g?t=498)
* 8:35 [Chef-client finished on db1, postgres installed](https://youtu.be/js9R-ebjV7g?t=515)
* 8:45 [knife node list shows db1 and app1](https://youtu.be/js9R-ebjV7g?t=525)
* 9:00 [vm delete recipe walkthru](https://youtu.be/js9R-ebjV7g?t=540)
* 9:25 [chef-client -z .../vmwaredemo-delete.rb](https://youtu.be/js9R-ebjV7g?t=565)
* 10:00 [app1 and db1 vms and nodes destroyed](https://youtu.be/js9R-ebjV7g?t=600)
* 10:36 [knife node list shows db1 and app1](https://youtu.be/js9R-ebjV7g?t=636)

## windows vm video walkthru

* 0:00 [install-winrm-vcair.bat](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=0)
* 0:20 [vcair-windows.rb](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=20)
* 0:30 [chef-client -z vcair-windows.rb](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=30)
* 2:30 [windows vm boots](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=150)
* 2:30 [windows vm boots](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=150)
* 4:20 [Log into VM](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=260)
* 4:40 [Winrm is reachable, chef is installed](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=280)
* 6:00 [Showing that iis is not install](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=360)
* 6:12 [Showing that iis is installed and running](https://www.youtube.com/watch?v=W8_XvXVsZaQ&t=360)


### files from walkthrus

#### environment_variables

```bash
export VCAIR_API_HOST='pXvYY-vcd.vchs.vmware.com'
export VCAIR_SSH_PASSWORD='NECESSARY_STRONG_AND_SECURE'
export VCAIR_ORG='M5116ORG-NUM'
export VCAIR_USERNAME='username@emaillogin.com'
export VCAIR_PASSWORD='VCAIR_LOGIN_PASS'
```

#### .chef/knife.rb

```ruby
current_dir = File.dirname(__FILE__)
#log_level                :info
log_level                :fatal
log_location             STDOUT
node_name                "wolfpack"
client_key               "#{current_dir}/wolfpack.pem"
validation_client_name   "vulk-validator"
validation_key           "#{current_dir}/vulk-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/vulk"
cookbook_path            ["#{current_dir}/../cookbooks"]
knife[:vcair_api_host] = "#{ENV['VCAIR_API_HOST']}"
knife[:vcair_username] = "#{ENV['VCAIR_USERNAME']}"
knife[:vcair_password] = "#{ENV['VCAIR_PASSWORD']}"
knife[:vcair_org] = "#{ENV['VCAIR_ORG']}"
```

#### vmwaredemo.rb

```ruby
# Run with: chef-client -z provisioning/vmwaredemo.rb
require 'chef/provisioning'

with_driver 'fog:Vcair'

with_chef_server 'https://api.opscode.com/organizations/vulk',
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

vcair_opts = {
    bootstrap_options: {
      image_name: 'CentOS64-64BIT',
      net: 'M511664989-4904-default-routed',
      memory: '1024', cpus: '1',
      use_private_ip_for_ssh: true
    },
    create_timeout: 600,
    start_timeout: 600,
    ssh_options: {
        timeout: 600,
        auth_methods: [ 'password' ],
        password: ENV['VCAIR_SSH_PASSWORD'],
        user_known_hosts_file: '/dev/null'
      }
}

machine 'linuxdemoapp1' do
  tag 'demo1'
  recipe 'apache2'
  machine_options vcair_opts
end

machine 'linuxdemodb1' do
  tag 'demo1'
  recipe 'postgresql'
  machine_options vcair_opts.merge({ memory: '4096', cpus: '2'})
end
```

#### vmwaredemo-delete.rb

```ruby
# Run with: chef-client -z provisioning/vmwaredemo-delete.rb

require 'chef/provisioning'

with_driver 'fog:Vcair'

with_chef_server 'https://api.opscode.com/organizations/vulk',
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine 'linuxdemoapp1' do
  action :destroy
end
```

#### vcair-windows.rb


```ruby
require 'chef/provisioning'

with_driver 'fog:Vcair'

with_chef_server 'https://api.opscode.com/organizations/vulk',
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

current_dir = File.dirname(__FILE__)
vcair_opts = {
  is_windows: true,
  winrm_options: {
    password: ENV['VCAIR_WINRM_PASSWORD'], # must match password set in customization-script
  },
  bootstrap_options: {
    protocol: 'winrm',
    image_name: 'W2K12-STD-64BIT',
    net: 'M511664989-4904-default-routed',
    memory: '4096', cpus: '2',
    customization_script: File.absolute_path("#{current_dir}/install-winrm-vcair.bat"),
    use_private_ip_for_ssh: true
  },
  create_timeout: 600,
  start_timeout: 600
}

machine 'windowsdemoiis1' do
  tag 'demo1'
  recipe 'iis'
  machine_options vcair_opts
end

```

#### vcair-windows-destroy.rb

```ruby
require 'chef/provisioning'

with_driver 'fog:Vcair'

with_chef_server 'https://api.opscode.com/organizations/vulk',
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine 'windowsdemoiis1' do
  action :destroy
end
```
