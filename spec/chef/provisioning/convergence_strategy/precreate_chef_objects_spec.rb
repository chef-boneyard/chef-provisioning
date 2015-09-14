require 'chef/provisioning/convergence_strategy/precreate_chef_objects'
describe Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects do
  let(:config) { nil }
  let(:convergence_options) { {} }
  let(:chef_server_url) { "https://mychefserver.com" }
  let(:action_handler) { double("ActionHandler") }

  let(:precreate_chef_objects_class) do
    pco = described_class.new(convergence_options, config)
    pco
  end

  describe "#new" do
    context "when intializing Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects" do
      it "can initialize described_class" do
        expect(precreate_chef_objects_class).to be_a(Chef::Provisioning::ConvergenceStrategy::PrecreateChefObjects)
      end
    end
  end

  describe "#chef_server" do
    context "when no convergence options are given" do
      let(:config) { {chef_server_url: 'https://mychefserver.com'} }
      it "returns cheffish value" do
        expect(precreate_chef_objects_class.chef_server).to eq(:chef_server_url => "https://mychefserver.com",
                                                               :options => {:client_name=>nil, :signing_key_filename=>nil})
      end
    end

    context "when convergence options given are \"'chef_server' => 'https://mychefserver.com'\"" do
      let(:convergence_options) { {chef_server: "https://mychefserver.com"} }
      it "returns 'https://mychefserver.com'" do
        expect(precreate_chef_objects_class.chef_server).to eq("https://mychefserver.com")
      end
    end
  end

  describe "#is_localhost" do
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
      precreate_chef_objects_class.send :client_rb_content, chef_server_url, "mynode"
    end

    context "when no convergence options are given" do
      it "generates client.rb with:
        client_key nil
        " do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options given are \"'client_pem_path' => '/etc/chef/client.pem'\"" do
      let(:convergence_options) { {client_pem_path: "/etc/chef/client.pem"} }
      it "generates client.rb with:
        client_key \"/etc/chef/client.pem\"
        " do
        expected_config = <<-CONFIG
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key "/etc/chef/client.pem"
        ssl_verify_mode :verify_peer
        CONFIG
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options given are \"'ssl_verify_mode' => :verify_peer'\"" do
      let(:convergence_options) { {ssl_verify_mode: :verify_peer} }
      it "generates client.rb with:
        ssl_verify_mode :verify_peer
        " do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options given are \"'ssl_verify_mode' => :verify_none'\"" do
      let(:convergence_options) { {ssl_verify_mode: :verify_none} }
      it "generates client.rb with:
        ssl_verify_mode :verify_none
        " do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_none
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when chef_server_url is HTTP" do
      let(:chef_server_url) { "http://mychefserver.com" }
      it "generates client.rb with:
        ssl_verify_mode :verify_none
        " do
        expected_config = <<-CONFIG
        chef_server_url "http://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_none
        CONFIG
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options given are \"'bootstrap_proxy' => 'http://myproxy'\"" do
      let(:convergence_options) { {bootstrap_proxy: "http://myproxy"} }
      it "generates client.rb with:
        http_proxy \"http://myproxy\"
        https_proxy \"http://myproxy\"
        " do
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

    context "when convergence options given are \"'chef_config' => 'some_config entry\\nother_config entry\\n'\"" do
      let(:convergence_options) { {chef_config: "some_config entry\nother_config entry\n",} }
      it "generates client.rb with:
        some_config entry
        other_config entry
        " do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        some_config entry
        other_config entry
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

    context "when convergence options given are \"'policy_group' => 'mygroup'\" and \"'policy_name' => 'myname'\"" do
      let(:convergence_options) { {policy_group: "mygroup",
                                   policy_name: "myname"}}
      it "generates client.rb with:
        use_policyfile true
        policy_document_native_api true
        policy_group \"mygroup\"
        policy_name \"myname\"
        " do
        expected_config = <<-EOM
        chef_server_url "https://mychefserver.com"
        node_name "mynode"
        client_key nil
        ssl_verify_mode :verify_peer
        # Policyfile Settings:
        use_policyfile true
        policy_document_native_api true
        policy_group "mygroup"
        policy_name "myname"
        EOM
        expect(client_rb_config).to eq(expected_config.gsub!(/^\s+/, ""))
      end
    end

  end
end
