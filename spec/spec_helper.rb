require 'simplecov'
SimpleCov.start do
  # add_filter do |source_file|
  #   # source_file.lines.count < 5
  #   source.filename =~ /^#{SimpleCov.root}\/chef-provisioning-fake/)
  # end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  #Chef::Log.level = :debug
  # Chef::Config[:log_level] = :warn
end
