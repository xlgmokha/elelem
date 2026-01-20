# frozen_string_literal: true

module Elelem
  module Net
    class OpenAI
      def initialize(model:, api_key:, base_url: "https://api.openai.com/v1", http: Elelem::Net.http)
        @url = "#{base_url}/chat/completions"
        @model, @api_key, @http = model, api_key, http
      end

      def fetch(messages, tools = [], &block)
        tool_calls = {}
        body = { model: @model, messages:, stream: true, tools:, tool_choice: "auto" }

        stream(body) do |json|
          delta = json.dig("choices", 0, "delta") || {}
          block.call(content: delta["content"], thinking: nil) if delta["content"]

          delta["tool_calls"]&.each do |tool_call|
            idx = tool_call["index"]
            tool_calls[idx] ||= { id: nil, name: nil, args: "" }
            tool_calls[idx][:id] ||= tool_call["id"]
            tool_calls[idx][:name] ||= tool_call.dig("function", "name")
            tool_calls[idx][:args] += tool_call.dig("function", "arguments").to_s
          end
        end

        finalize_tools(tool_calls)
      end

      private

      def stream(body, &block)
        @http.post(@url, headers: { "Authorization" => "Bearer #{@api_key}" }, body:) do |res|
          raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(::Net::HTTPSuccess)

          buf = ""
          res.read_body do |chunk|
            buf += chunk
            while (i = buf.index("\n"))
              line = buf.slice!(0, i + 1).strip
              next unless line.start_with?("data: ") && line != "data: [DONE]"
              block.call(JSON.parse(line[6..]))
            end
          end
        end
      end

      def finalize_tools(tool_calls)
        tool_calls.values.map do |tool_call|
          {
            id: tool_call[:id],
            name: tool_call[:name],
            arguments: JSON.parse(tool_call[:args])
          }
        end
      end
    end
  end
end
