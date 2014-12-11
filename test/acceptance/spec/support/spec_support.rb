require 'chef_zero/rspec'
require 'chef/server_api'
require 'cheffish/basic_chef_client'
require 'support/repository_support'

module SpecSupport
  include ChefZero::RSpec

  def when_the_chef_12_server(*args, &block)
    if Gem::Version.new(ChefZero::VERSION) >= Gem::Version.new('3.1')
      when_the_chef_server(*args, :osc_compat => false, :single_org => false, &block)
    end
  end

  def self.extended(klass)
    klass.class_eval do
      extend RepositorySupport

      def get(*args)
        Chef::ServerAPI.new.get(*args)
      end

      def chef_run
        converge if !@converged
        event_sink.events
      end

      def event_sink
        @event_sink ||= EventSink.new
      end

      def basic_chef_client
        @basic_chef_client ||= begin
          Cheffish::BasicChefClient.new(nil, event_sink)
        end
      end

      def load_recipe(&block)
        basic_chef_client.load_block(&block)
      end

      def run_recipe(&block)
        load_recipe(&block)
        converge
      end

      def reset_chef_client
        @event_sink = nil
        @basic_chef_client = nil
        @converged = false
      end

      def converge
        if @converged
          raise "Already converged! Cannot converge twice, that's bad mojo."
        end
        @converged = true
        basic_chef_client.converge
      end
    end
  end

  def with_recipe(&block)
    before :each do
      load_recipe(&block)
    end

    after :each do
      if !@converged
        raise "Never tried to converge!"
      end
    end
  end

  def with_converge(&block)
    before :each do
      load_recipe(&block) if block_given?
      converge
    end
  end

  class EventSink
    def initialize
      @events = []
    end

    attr_reader :events

    def method_missing(method, *args)
      @events << [ method, *args ]
    end
  end
end

RSpec::Matchers.define :have_updated do |resource_name, *expected_actions|
  match do |actual|
    actual_actions = actual.select { |event, resource, action| event == :resource_updated && resource.to_s == resource_name }.map { |event, resource, action| action }
    expect(actual_actions).to eq(expected_actions)
  end
  failure_message do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
  failure_message_when_negated do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would not #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
end

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :each do
    Chef::Config.reset
  end
end

require 'chef/providers'
