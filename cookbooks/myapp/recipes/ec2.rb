require 'chef_metal_fog'

ec2testdir = File.expand_path('~/ec2test')

directory ec2testdir

with_driver 'fog:AWS:default'

fog_key_pair 'me'
