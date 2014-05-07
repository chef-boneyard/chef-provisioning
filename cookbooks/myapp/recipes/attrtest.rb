machine 'blah' do
  default_attributes({ 'defaulty' => 1 })
  override_attributes({ 'overridey' => 1 })
  normal_attributes({ 'normaly' => 1 })
  run_list [ 'recipe[ontarget::printattrs]' ]
  converge true
end
