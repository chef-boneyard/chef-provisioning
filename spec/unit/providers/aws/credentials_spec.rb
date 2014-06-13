require 'chef_metal_fog/providers/aws/credentials'

describe ChefMetalFog::Providers::AWS::Credentials do
  describe "#load_ini" do
    let(:aws_credentials_ini_file) { File.join(File.expand_path('../../../../support', __FILE__), 'aws/ini-file.ini') }

    before do
      described_class.load_ini(aws_credentials_ini_file)
    end

    it "should load a default profile" do
      expect(described_class['default']).to include(:aws_access_key_id)
    end

    it "should load the correct values" do
      expect(described_class['default'][:aws_access_key_id]).to eq "12345"
    end

    it "should load several profiles" do
      expect(described_class.keys.length).to eq 2
    end
  end

  describe "#load_csv" do
    let(:aws_credentials_csv_file) { File.join(File.expand_path('../../../../support', __FILE__), 'aws/config-file.csv') }
    before do
      described_class.load_csv(aws_credentials_csv_file)
    end

    it "should load a single profile" do
      expect(described_class['default']).to include(:aws_access_key_id)
    end

    it "should load the correct values" do
      expect(described_class['default'][:aws_access_key_id]).to eq "12345"
    end

    it "should load several profiles" do
      expect(described_class.keys.length).to eq 2
    end
  end
end
