# frozen_string_literal: true

RSpec.describe Elelem::Net::Ollama do
  subject(:client) { described_class.new(model: "gpt-oss:latest", http:, **params) }

  let(:params) { {} }
  let(:messages) { [{ role: "user", content: "hi" }] }
  let(:body) { http.body }

  let(:response) do
    ::Net::HTTPOK.new("1.1", "200", "OK").tap do |it|
      allow(it).to receive(:read_body).and_yield(%({"done":true,"message":{}}\n))
    end
  end

  let(:http) do
    Class.new do
      attr_reader :body

      def initialize(response)
        @response = response
      end

      def post(_url, body:)
        @body = body
        yield @response
      end
    end.new(response)
  end

  describe "#fetch" do
    it "sends only model, messages and stream by default" do
      client.fetch(messages) { }

      expect(body).to eq(model: "gpt-oss:latest", messages:, stream: true, think: "medium", keep_alive: "5m")
    end

    it "sends tools when present" do
      tools = [{ type: "function", function: { name: "read" } }]

      client.fetch(messages, tools) { }

      expect(body[:tools]).to eq(tools)
    end

    context "with tuning keywords" do
      let(:params) { { think: "high", keep_alive: "30m", options: { num_ctx: 32_768 } } }

      it "sends them in the request body" do
        client.fetch(messages) { }

        expect(body).to include(think: "high", keep_alive: "30m", options: { num_ctx: 32_768 })
      end
    end

    context "with an empty options hash" do
      let(:params) { { options: {} } }

      it "omits options" do
        client.fetch(messages) { }

        expect(body).not_to have_key(:options)
      end
    end

    context "with passthrough params" do
      let(:params) { { params: { format: "json", truncate: false, top_logprobs: 3 } } }

      it "merges them into the request body" do
        client.fetch(messages) { }

        expect(body).to include(format: "json", truncate: false, top_logprobs: 3)
      end
    end

    context "with a passthrough param that collides with a keyword" do
      let(:params) { { think: "low", params: { think: "high" } } }

      it "prefers the passthrough value" do
        client.fetch(messages) { }

        expect(body[:think]).to eq("high")
      end
    end
  end
end
