require 'spec_helper'
require 'chef_metal_fog/fog_driver'

describe ChefMetalFog::FogDriver do

  describe ".from_url" do
    subject { ChefMetalFog::FogDriver.from_provider('TestDriver', {}) }

    it "should return the correct class" do
      expect(subject).to be_an_instance_of ChefMetalFog::Providers::TestDriver
    end

    it "should call the target compute_options_for" do
      expect(ChefMetalFog::Providers::TestDriver).to receive(:compute_options_for)
        .with('TestDriver', anything, {}).and_return([{}, 'test']).twice
      subject
    end

  end

  describe "when creating a new class" do
    it "should return the correct class" do
      test = ChefMetalFog::FogDriver.new('fog:TestDriver:foo', {})
      expect(test).to be_an_instance_of ChefMetalFog::Providers::TestDriver
    end

    it "should populate config" do
      test = ChefMetalFog::FogDriver.new('fog:TestDriver:foo', {test: "metal"})
      expect(test.config[:test]).to eq "metal"
    end
  end
end
