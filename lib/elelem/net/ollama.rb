# frozen_string_literal: true

module Elelem
  module Net
    class Ollama
      def initialize(model:, host: "localhost:11434", http: Elelem::Net.http)
        @url = normalize_url(host)
        @model = model
        @http = http
      end

      def fetch(messages, tools = [], &block)
        tool_calls = []
        body = build_request_body(messages, tools)

        stream(body) do |event|
          handle_event(event, tool_calls, &block)
        end

        tool_calls
      end

      private

      def normalize_url(host)
        base = host.start_with?("http") ? host : "http://#{host}"
        "#{base}/api/chat"
      end

      def build_request_body(messages, tools)
        { model: @model, messages:, tools:, stream: true }
      end

      def handle_event(event, tool_calls, &block)
        message = event["message"] || {}

        unless event["done"]
          block.call(content: message["content"], thinking: message["thinking"])
        end

        if message["tool_calls"]
          tool_calls.concat(parse_tool_calls(message["tool_calls"]))
        end
      end

      def stream(body)
        @http.post(@url, body:) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(::Net::HTTPSuccess)

          read_ndjson_stream(response) { |event| yield event }
        end
      end

      def read_ndjson_stream(response)
        buffer = String.new

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n"))
            line = buffer.slice!(0, index + 1)
            yield JSON.parse(line)
          end
        end
      end

      def parse_tool_calls(tool_calls)
        tool_calls.map do |tool_call|
          {
            id: tool_call["id"],
            name: tool_call.dig("function", "name"),
            arguments: tool_call.dig("function", "arguments") || {}
          }
        end
      end
    end
  end
end
