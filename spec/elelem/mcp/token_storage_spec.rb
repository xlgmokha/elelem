# frozen_string_literal: true

RSpec.describe Elelem::MCP::TokenStorage do
  subject { described_class.new }

  let(:resource_url) { "https://example.com/mcp" }
  let(:token_dir) { File.expand_path("~/.config/elelem/tokens") }

  after do
    Dir.glob(File.join(token_dir, "*.json")).each { |f| File.delete(f) rescue nil }
  end

  describe "#save and #load" do
    it "stores and retrieves tokens" do
      subject.save(resource_url, access_token: "abc123", refresh_token: "refresh456", expires_in: 3600)

      stored = subject.load(resource_url)
      expect(stored[:access_token]).to eq("abc123")
      expect(stored[:refresh_token]).to eq("refresh456")
      expect(stored[:expires_at]).to be > Time.now.to_i
    end

    it "returns nil for unknown resource" do
      expect(subject.load("https://unknown.com")).to be_nil
    end

    it "handles missing refresh_token" do
      subject.save(resource_url, access_token: "abc123")

      stored = subject.load(resource_url)
      expect(stored[:access_token]).to eq("abc123")
      expect(stored[:refresh_token]).to be_nil
    end
  end

  describe "#save_client and #load_client" do
    it "stores and retrieves client registration" do
      client_data = { "client_id" => "elelem-123", "client_secret" => nil }
      subject.save_client(resource_url, client_data)

      stored = subject.load_client(resource_url)
      expect(stored[:client_id]).to eq("elelem-123")
    end

    it "returns nil for unknown client" do
      expect(subject.load_client("https://unknown.com")).to be_nil
    end
  end

  describe "file permissions" do
    it "creates token files with 0600 permissions" do
      subject.save(resource_url, access_token: "secret")

      files = Dir.glob(File.join(token_dir, "*.json"))
      expect(files).not_to be_empty
      files.each do |f|
        mode = File.stat(f).mode & 0o777
        expect(mode).to eq(0o600)
      end
    end
  end
end
