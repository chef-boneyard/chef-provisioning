require 'spec_helper'
require 'chef_metal_test_suite/cli'
require 'chef_metal_test_suite/config'

describe ChefMetalTestSuite::Cli do
  let(:cli) { ChefMetalTestSuite::Cli.new }

  context "no provided args" do
    before { cli.run }

    it "defaults driver" do
      expect(ChefMetalTestSuite::Config.metal_driver).to eq(:vagrant)
    end
    
    it "does not set test recipes" do
      cli.cli_arguments.shift # the spec likes to add itself to cli_arguments. NUKE!
      expect(ChefMetalTestSuite::Config.test_recipes).to eq([])
    end
  end

  context "provided args" do
    before { cli.run(['-d', 'fog', 'test1', 'test2']) }
    it "overrides config" do
      expect(ChefMetalTestSuite::Config.metal_driver).to eq(:fog)
    end

    it "sets test recipes" do
      expect(ChefMetalTestSuite::Config.test_recipes).to eq(['test1', 'test2'])
    end
  end

  context "invalid args" do
    it "raises exception" do
      expect { raise cli.run(['-d', 'mycloud']) }.to raise_error(ArgumentError, /mycloud/)
    end
  end

end
