# frozen_string_literal: true

module Elelem
  module Net
    class Ollama
      def initialize(model:, host: "localhost:11434", http: Elelem::Net.http)
        @url = "#{host.start_with?('http') ? host : "http://#{host}"}/api/chat"
        @model, @http = model, http
      end

      def fetch(messages, tools = [], &block)
        tool_calls = []

        stream({ model: @model, messages:, tools:, stream: true }) do |json|
          msg = json["message"] || {}
          block.call(content: msg["content"], thinking: msg["thinking"]) unless json["done"]
          tool_calls.concat(parse_tools(msg["tool_calls"])) if msg["tool_calls"]
        end

        tool_calls
      end

      private

      def stream(body, &block)
        @http.post(@url, body:) do |res|
          raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(::Net::HTTPSuccess)
          buf = ""
          res.read_body do |chunk|
            buf += chunk
            while (i = buf.index("\n"))
              block.call(JSON.parse(buf.slice!(0, i + 1)))
            end
          end
        end
      end

      def parse_tools(tool_calls)
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
