require 'chef/provisioning/convergence_strategy/precreate_chef_objects'

describe Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects do
  let(:action_handler) { double("ActionHandler") }

  let(:precreate_chef_objects_class) do
    pco = described_class.new(convergence_options, config)
    pco
  end

  describe "#new" do
    context "when intializing Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects" do
      let(:config) { nil }
      let(:convergence_options) { {} }
      it "can initialize described_class" do
        expect(precreate_chef_objects_class).to be_a(Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects)
      end
    end
  end

  describe "#chef_server" do

    context "when no convergence options are given" do
      let(:config) { {chef_server_url: 'https://mychefserver.com'} }
      let(:convergence_options) { {} }
      it "returns cheffish value" do
        expect(precreate_chef_objects_class.chef_server).to eq(:chef_server_url => "https://mychefserver.com",
                                             :options => {:client_name=>nil, :signing_key_filename=>nil})
      end
    end

    context "when convergence options chef_server is given" do
      let(:config) { nil }
      let(:convergence_options) { {chef_server: "https://mychefserver.com"} }
      it "returns chef_server value" do
        expect(precreate_chef_objects_class.chef_server).to eq("https://mychefserver.com")
      end
    end

  end

  describe "#is_localhost" do
    let(:config) { nil }
    let(:convergence_options) { {} }

    let(:is_localhost) do
      tcrb = precreate_chef_objects_class.send :is_localhost, host
      tcrb
    end

    context "when host is localhost" do
      let(:host) { "localhost" }
      it "returns true" do
        expect(is_localhost).to eq(true)
      end
    end

    context "when host is 127.0.0.1" do
      let(:host) { "127.0.0.1" }
      it "returns true" do
        expect(is_localhost).to eq(true)
      end
    end

    context "when host is [::1]" do
      let(:host) { "[::1]" }
      it "returns true" do
        expect(is_localhost).to eq(true)
      end
    end

    context "when host is 192.168.1.11" do
      let(:host) { "192.168.1.11" }
      it "returns false" do
        expect(is_localhost).to eq(false)
      end
    end

  end

  describe "#client_rb_content" do
    let(:client_rb_config) do
      tcrb = precreate_chef_objects_class.send :client_rb_content, chef_server_url, "mynode"
      tcrb
    end

    let(:config) { nil }
    let(:chef_server_url) { "https://mychefserver.com" }
    let(:convergence_options) { {} }

    context "when no convergence options are given" do
      it "generates client.rb with nil client_pem_path" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options client_pem_path is given" do
      let(:convergence_options) { {client_pem_path: "/etc/chef/client.pem"} }
      it "generates client.rb with client_pem_path" do
        expected_config = <<-CONFIG
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key "/etc/chef/client.pem"
        ssl_verify_mode :verify_peer
        CONFIG
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options ssl_verify_mode given is :verify_peer" do
      let(:convergence_options) { {ssl_verify_mode: :verify_peer} }
      it "generates client.rb with verify_peer" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options ssl_verify_mode given is :verify_none" do
      let(:convergence_options) { {ssl_verify_mode: :verify_none} }
      it "generates client.rb with verify_none" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_none
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when chef_server_url is http" do
      let(:chef_server_url) { "http://mychefserver.com" }
      it "generates client.rb with ssl_verify_mode :verify_none and http chef_server_url" do
        expected_config = <<-CONFIG
        chef_server_url "http://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_none
        CONFIG
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options bootstrap_proxy is given" do
      let(:convergence_options) { {bootstrap_proxy: "http://myproxy"} }
      it "generates client.rb with bootstrap_proxy" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        http_proxy "http://myproxy"
        https_proxy "http://myproxy"
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options chef_config given" do
      let(:convergence_options) { {chef_config: "some_config entry\n"} }
      it "generates client.rb with chef_config" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        some_config entry
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options client_pem_path, bootstrap_proxy and chef_config are given" do
      let(:convergence_options) { {client_pem_path: "/etc/chef/client.pem",
                                   bootstrap_proxy: "http://myproxy",
                                   chef_config: "some_config entry\n"}}
      it "generates client.rb with client_pem_path, bootstrap_proxy and chef_config" do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key "/etc/chef/client.pem"
        ssl_verify_mode :verify_peer
        http_proxy "http://myproxy"
        https_proxy "http://myproxy"
        some_config entry
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

  end
end
