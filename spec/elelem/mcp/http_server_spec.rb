# frozen_string_literal: true

RSpec.describe Elelem::MCP::HttpServer do
  let(:url) { "https://mcp.example.com/sse" }
  let(:http) { double("http") }

  describe "#parse_sse" do
    subject { described_class.allocate }

    it "parses single SSE event" do
      response = double
      allow(response).to receive(:read_body).and_yield("data: {\"result\": \"ok\"}\n\n")

      result = subject.send(:parse_sse, response)
      expect(result).to eq({ "result" => "ok" })
    end

    it "parses chunked SSE events" do
      response = double
      chunks = ["data: {\"id\"", ": 1}\n\ndata: {\"id\": 2}\n\n"]
      allow(response).to receive(:read_body) do |&block|
        chunks.each { |c| block.call(c) }
      end

      result = subject.send(:parse_sse, response)
      expect(result).to eq({ "id" => 2 })
    end

    it "ignores non-data lines" do
      response = double
      allow(response).to receive(:read_body).and_yield("event: message\ndata: {\"value\": 42}\n\n")

      result = subject.send(:parse_sse, response)
      expect(result).to eq({ "value" => 42 })
    end

    it "returns last event when multiple present" do
      response = double
      allow(response).to receive(:read_body).and_yield("data: {\"n\": 1}\n\ndata: {\"n\": 2}\n\n")

      result = subject.send(:parse_sse, response)
      expect(result).to eq({ "n" => 2 })
    end
  end

  describe "#parse_response" do
    subject { described_class.allocate }

    it "parses JSON response" do
      response = double(content_type: "application/json", body: '{"tools": []}')
      result = subject.send(:parse_response, response)
      expect(result).to eq({ "tools" => [] })
    end

    it "parses SSE response" do
      response = double(content_type: "text/event-stream")
      allow(response).to receive(:read_body).and_yield("data: {\"ok\": true}\n\n")

      result = subject.send(:parse_response, response)
      expect(result).to eq({ "ok" => true })
    end

    it "returns nil for empty body" do
      response = double(content_type: "application/json", body: "")
      result = subject.send(:parse_response, response)
      expect(result).to be_nil
    end
  end

  describe "#request_headers" do
    subject do
      server = described_class.allocate
      server.instance_variable_set(:@headers, {})
      server.instance_variable_set(:@session_id, nil)
      server.instance_variable_set(:@access_token, nil)
      server
    end

    it "includes Accept header" do
      headers = subject.send(:request_headers)
      expect(headers["Accept"]).to eq("application/json, text/event-stream")
    end

    it "includes session ID when set" do
      subject.instance_variable_set(:@session_id, "abc123")
      headers = subject.send(:request_headers)
      expect(headers["Mcp-Session-Id"]).to eq("abc123")
    end

    it "includes authorization when access_token set" do
      subject.instance_variable_set(:@access_token, "token123")
      headers = subject.send(:request_headers)
      expect(headers["Authorization"]).to eq("Bearer token123")
    end
  end
end
