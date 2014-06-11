require 'spec_helper'
require 'chef_metal_fog/fog_driver'

describe ChefMetalFog::FogDriver do
  module ChefMetalFog::Drivers
    class TestDriver < ChefMetalFog::FogDriver
      attr_reader :config
      def initialize(driver_url, config)
        super
      end
    end
  end

  describe "when creating a new class" do
    it "should return the correct class" do
      test = ChefMetalFog::FogDriver.new('fog:TestDriver:foo', {})
      expect(test).to be_an_instance_of ChefMetalFog::Drivers::TestDriver
    end

    it "should populate config" do
      test = ChefMetalFog::FogDriver.new('fog:TestDriver:foo', {test: "metal"})
      expect(test.config[:test]).to eq "metal"
    end
  end
end
