module ChefMetalFog::Providers
  class TestDriver < ChefMetalFog::FogDriver
    ChefMetalFog::FogDriver.register_provider_class('TestDriver', ChefMetalFog::Providers::TestDriver)

    attr_reader :config
    def initialize(driver_url, config)
      super
    end

    def self.compute_options_for(provider, id, config)
      [config, 'test']
    end
  end
end
