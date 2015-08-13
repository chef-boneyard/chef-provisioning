require 'chef/provisioning/convergence_strategy/ignore_convergence_failure'

class TestConvergenceStrategyError < RuntimeError; end

class TestConvergeClass
  attr_reader :convergence_options, :test_error
  def initialize(convergence_options, test_error)
    @convergence_options = convergence_options
    @test_error = test_error
  end
  def converge(action_handler, machine)
    test_error.call
  end
end

describe Chef::Provisioning::ConvergenceStrategy::IgnoreConvergenceFailure do

  let(:test_class) do
    t = TestConvergeClass.new(convergence_options, test_error)
    t.extend(Chef::Provisioning::ConvergenceStrategy::IgnoreConvergenceFailure)
    t
  end
  let(:action_handler) { double("ActionHandler") }

  shared_examples "does not raise an error" do
    it "does not raise an error" do
      expect(action_handler).to receive(:performed_action)
      expect { test_class.converge(action_handler, nil) }.to_not raise_error
    end
  end

  context "when ignore_failures is a single Fixnum" do
    let(:convergence_options) { {ignore_failure: 1} }
    let(:test_error) { proc { exit(1) } }
    include_examples "does not raise an error"
  end

  context "when ignore_failures is an array of Fixnum" do
    let(:convergence_options) { {ignore_failure: [1, 2]} }
    let(:test_error) { proc { exit(1) } }
    include_examples "does not raise an error"
  end

  context "when ignore_failures is a Range" do
    let(:convergence_options) { {ignore_failure: [1, 5..10]} }
    let(:test_error) { proc { exit(6) } }
    include_examples "does not raise an error"
  end

  context "when ignore_failures is a single error class" do
    let(:convergence_options) { {ignore_failure: TestConvergenceStrategyError} }
    let(:test_error) { proc { raise TestConvergenceStrategyError } }
    include_examples "does not raise an error"
  end

  context "when ignore_failures is an array of errors" do
    let(:convergence_options) { {ignore_failure: [TestConvergenceStrategyError, NoMethodError]} }
    let(:test_error) { proc { raise TestConvergenceStrategyError } }
    include_examples "does not raise an error"
  end

  context "when ignore_failures is a different error" do
    let(:convergence_options) { {ignore_failure: [NoMethodError]} }
    let(:test_error) { proc { raise TestConvergenceStrategyError } }
    it "does not catch the TestConvergenceStrategyError" do
      expect { test_class.converge(action_handler, nil) }.to raise_error(TestConvergenceStrategyError)
    end
  end

  context "when ignore_failures is true" do
    let(:convergence_options) { {ignore_failure: true} }

    context "and test_error is a RuntimeError" do
      let(:test_error) { proc { raise TestConvergenceStrategyError } }
      include_examples "does not raise an error"
    end

    context "and test_error is a SystemExit error" do
      let(:test_error) { proc { exit(1) } }
      it "does not catch SystemExit errors" do
        expect { test_class.converge(action_handler, nil) }.to raise_error(SystemExit)
      end
    end
  end

end
