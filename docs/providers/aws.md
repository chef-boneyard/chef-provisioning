# AWS Provider

## Compute (EC2)

AWS instance information can be specified via `bootstrap_options`:

```ruby
machine 'blah' do
  machine_options bootstrap_options: { image_id: 'ami-2389472398', instance_type: 'x-small' }
end
```

All bootstrap options are **exactly** the same as the options passed to ec2.instances.create().  Refer to documentation here:

https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/InstanceCollection.html#create-instance_method
