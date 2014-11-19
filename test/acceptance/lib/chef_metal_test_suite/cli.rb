require 'mixlib/cli'

module ChefMetalTestSuite
  # This class, along with the config class,
  # where originially intended to create an API
  # based approach for configuring the tests
  # then executing accordingly.  (whether api or cli)
  # rspec tagging and custom settings turned out to
  # be a more elegent solution, and validation
  # of what can run in combination is handled in the
  # spec files directly.

  # Perhaps this work can be refactored to create a
  # a config model and cli for running Rspec, but
  # mostly likely won't be necessary, and the
  # classes can be removed from the project.
  class Cli
    include Mixlib::CLI

    option :server_type,
      :short => '-s SERVER TYPE',
      :long => '--server-type SERVER TYPE',
      :default => :zero,
      :description => 'Chef Server Type',
      :proc => Proc.new { |s| s.to_sym }

    option :metal_driver,
      :short => '-d METAL DRIVER',
      :long => '--metal-driver METAL DRIVER',
      :default => :vagrant,
      :description => 'Chef Metal Driver',
      :proc => Proc.new { |d| d.to_sym }

    option :platform,
      :short => '-p PLATFORM',
      :long => '--plaftorm PLATFORM',
      :default => :ubuntu,
      :description => 'Operating System Plaftorm',
      :proc => Proc.new { |p| p.to_sym }

    option :platform_version,
      :short => '-pv PLATFORM VERSION',
      :long => '--platform-version PLATFORM VERSION',
      :default => '14.04',
      :description => 'Operating System Plaftorm Version'

    option :create_databag,
      :short => '-b',
      :long => '--create-databag',
      :boolean => true,
      :description => 'Writes the configuration to a local databag'

    option :help,
      :short => "-h",
      :long => "--help",
      :description => "Show this message",
      :on => :tail,
      :boolean => true,
      :show_options => true,
      :exit => 0

    def run(argv=ARGV)
      parse_options(argv)
      ChefMetalTestSuite::Config.test_recipes = cli_arguments
      ChefMetalTestSuite::Config.merge!(config)
      ChefMetalTestSuite::Config.validate(true)
    end
  end
end
