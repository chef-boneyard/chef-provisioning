# work with John
# this test is will need:
# a) on an optimal action cycle path
# b) verify if node is up to date
[:allocate, :ready, :converge, :destroy].each { |action_name|
  machine 'cycle-actions' do
    action action_name
    recipe 'build-essential'
  end
}
