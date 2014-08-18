require 'chef_metal'

with_driver 'fog:AWS'

machine 'testaws'

with_driver 'fog:DigitalOcean'

machine 'testdigitalocean'

with_driver 'vagrant'

machine 'testvagrant'
