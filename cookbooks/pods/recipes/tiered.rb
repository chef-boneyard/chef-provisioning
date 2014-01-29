
include_recipe 'stacks::vagrant'
include_recipe 'os::ubuntu-12.04'
include_recipe 'machines::back-end'
include_recipe 'machines::front-end'
