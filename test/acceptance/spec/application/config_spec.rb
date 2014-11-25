require 'spec_helper'
require 'chef_metal_test_suite/config'

describe ChefMetalTestSuite::Config do

  context "#validate" do
    before(:each) do
      ChefMetalTestSuite::Config.reset
    end

    it "accepts defaults" do
      expect(ChefMetalTestSuite::Config.validate).to eq([])
    end

    it "invalidates server" do
      ChefMetalTestSuite::Config.server_type = :frankenchef
      expect(ChefMetalTestSuite::Config.validate).to match([/frankenchef/])
    end

    it "invalidates driver" do
      ChefMetalTestSuite::Config.metal_driver = :mycloud
      expect(ChefMetalTestSuite::Config.validate).to match([/mycloud/])
    end

    it "invalidates platform" do
      ChefMetalTestSuite::Config.platform = :gentoo
      expect(ChefMetalTestSuite::Config.validate).to match([/gentoo/])
    end

    it "invalidates platform version" do
      ChefMetalTestSuite::Config.platform_version = '99.99'
      expect(ChefMetalTestSuite::Config.validate).to match([/99.99/])
    end

    it "returns all errors" do
      ChefMetalTestSuite::Config.server_type = :frankenchef
      ChefMetalTestSuite::Config.metal_driver = :mycloud
      expect(ChefMetalTestSuite::Config.validate).to match([/frankenchef/, /mycloud/])
    end
  end
end
