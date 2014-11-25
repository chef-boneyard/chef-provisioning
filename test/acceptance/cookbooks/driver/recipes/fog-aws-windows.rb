include_recipe 'driver::fog-aws'

with_machine_options :bootstrap_options => {
  :image_id => 'ami-21f0bc11',
  :instance_type => 't1.micro'
}
