# frozen_string_literal: true

RSpec.describe Elelem::MCP::OAuth do
  let(:resource_url) { "https://mcp.example.com/sse" }
  let(:http) { double("http") }
  let(:storage) { instance_double(Elelem::MCP::TokenStorage) }

  subject { described_class.new(resource_url, http: http) }

  before do
    allow(Elelem::MCP::TokenStorage).to receive(:new).and_return(storage)
  end

  describe "#token" do
    context "with valid cached token" do
      it "returns cached access_token" do
        allow(storage).to receive(:load).with(resource_url).and_return({
          access_token: "cached_token",
          expires_at: Time.now.to_i + 3600
        })

        expect(subject.token).to eq("cached_token")
      end
    end

    context "with expired token and refresh_token" do
      let(:auth_metadata) do
        {
          "authorization_endpoint" => "https://auth.example.com/authorize",
          "token_endpoint" => "https://auth.example.com/token",
          "registration_endpoint" => "https://auth.example.com/register"
        }
      end

      it "refreshes using refresh_token" do
        allow(storage).to receive(:load).with(resource_url).and_return({
          access_token: "old_token",
          refresh_token: "refresh_abc",
          expires_at: Time.now.to_i - 100
        })

        allow(storage).to receive(:load_client).with(resource_url).and_return({
          client_id: "elelem-123"
        })

        resource_response = double(body: { "authorization_servers" => ["https://auth.example.com"] }.to_json)
        auth_response = double(body: auth_metadata.to_json)
        token_response = double(body: { "access_token" => "new_token", "expires_in" => 3600 }.to_json)

        allow(http).to receive(:get).with("https://mcp.example.com/.well-known/oauth-protected-resource").and_yield(resource_response)
        allow(http).to receive(:get).with("https://auth.example.com/.well-known/oauth-authorization-server").and_yield(auth_response)
        allow(http).to receive(:post).and_yield(token_response)
        allow(storage).to receive(:save)

        expect(subject.token).to eq("new_token")
      end
    end
  end

  describe "PKCE generation" do
    it "generates valid verifier and challenge" do
      verifier, challenge = subject.send(:generate_pkce)

      expect(verifier.length).to be >= 43
      expect(challenge.length).to be >= 43
      expect(challenge).not_to include("+", "/", "=")

      expected_challenge = Base64.urlsafe_encode64(
        Digest::SHA256.digest(verifier),
        padding: false
      )
      expect(challenge).to eq(expected_challenge)
    end
  end

  describe "expiration check" do
    it "considers token expired when within 60 seconds of expiry" do
      stored = { expires_at: Time.now.to_i + 30 }
      expect(subject.send(:expired?, stored)).to be true
    end

    it "considers token valid when more than 60 seconds remain" do
      stored = { expires_at: Time.now.to_i + 120 }
      expect(subject.send(:expired?, stored)).to be false
    end

    it "considers token valid when no expires_at" do
      stored = { expires_at: nil }
      expect(subject.send(:expired?, stored)).to be false
    end
  end
end
