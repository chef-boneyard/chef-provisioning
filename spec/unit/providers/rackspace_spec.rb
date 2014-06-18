require 'chef_metal_fog/fog_driver'
require 'chef_metal_fog/providers/rackspace'

describe ChefMetalFog::Providers::Rackspace do
  subject { ChefMetalFog::FogDriver.from_provider('Rackspace',{}) }

  it "returns the correct driver" do
    expect(subject).to be_an_instance_of ChefMetalFog::Providers::Rackspace
  end

  it "has a fog backend" do
    pending unless Fog.mock?
    expect(subject.compute).to be_an_instance_of Fog::Compute::RackspaceV2::Mock
  end

end
