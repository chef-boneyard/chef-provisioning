require 'chef/provisioning'

machine_batch do
  machines %w(primary secondary web1 web2)
end

machine_batch do
  machine 'primary' do
    recipe 'initial_ha_setup'
  end
end

machine_batch do
  machine 'secondary' do
    recipe 'initial_ha_setup'
  end
end

machine_batch do
  %w(primary secondary).each do |name|
    machine name do
      recipe 'rest_of_my_shit'
    end
  end
end
