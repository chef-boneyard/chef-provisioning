RSpec.shared_context "run with driver" do |driver_args|
  require 'cheffish/rspec/chef_run_support'
  extend Cheffish::RSpec::ChefRunSupport

  include_context "with a chef repo"

  driver_object = Chef::Provisioning.driver_for_url(driver_args[:driver_string])

  # globally set this as the driver. overridden by a resource's :driver attribute.
  before { Chef::Config.driver(driver_object) }

  let(:provisioning_driver) { driver_object }

  # only class methods are available outside of examples.
  def self.with_chef_server(description = "is running", *options, &block)

    # no need to repeat these every time.
    args = { organization: "spec_tests", server_scope: :context, port: 8900..9000 }
    args = args.merge(options.last) if options.last.is_a?(Hash)

    # this ends up in ChefZero::RSpec::RSpecClassMethods#when_the_chef_server, which defines all its code
    # inside an RSpec context and then runs `instance_eval` on &block--which means it's only available as a
    # block operator. it's not obviously impossible to factor out the code into a shared_context that we could
    # include as above with "with a chef repo", but that's a chef-zero patch.
    when_the_chef_12_server description, args, &block
  end
end
