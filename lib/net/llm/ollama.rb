# frozen_string_literal: true

module Net
  module Llm
    class Ollama
      def initialize(model:, host: ENV.fetch("OLLAMA_HOST", "localhost:11434"), http: Net::Llm.http)
        @url = "#{host.start_with?('http') ? host : "http://#{host}"}/api/chat"
        @model, @http = model, http
      end

      def fetch(messages, tools = [], &block)
        content, thinking, tool_calls = "", "", []

        stream({ model: @model, messages:, tools:, stream: true }) do |json|
          msg = json["message"] || {}
          content += msg["content"].to_s
          thinking += msg["thinking"].to_s
          tool_calls.concat(parse_tools(msg["tool_calls"])) if msg["tool_calls"]

          block.call(json["done"] ?
            { type: :complete, content:, thinking: nilify(thinking), tool_calls: } :
            { type: :delta, content: msg["content"], thinking: msg["thinking"], tool_calls: nil })
        end
      end

      private

      def stream(body, &block)
        @http.post(@url, body:) do |res|
          raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
          buf = ""
          res.read_body do |chunk|
            buf += chunk
            while (i = buf.index("\n"))
              block.call(JSON.parse(buf.slice!(0, i + 1)))
            end
          end
        end
      end

      def parse_tools(tcs)
        tcs.map { |tc| { id: tc["id"], name: tc.dig("function", "name"), arguments: tc.dig("function", "arguments") || {} } }
      end

      def nilify(s) = s.empty? ? nil : s
    end
  end
end
