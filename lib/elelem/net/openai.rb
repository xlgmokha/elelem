# frozen_string_literal: true

module Elelem
  module Net
    class OpenAI
      def initialize(model:, api_key:, base_url: "https://api.openai.com/v1", http: Elelem::Net.http)
        @url = "#{base_url}/chat/completions"
        @model = model
        @api_key = api_key
        @http = http
      end

      def fetch(messages, tools = [], &block)
        tool_calls = {}
        body = build_request_body(messages, tools)

        stream(body) do |event|
          handle_event(event, tool_calls, &block)
        end

        finalize_tool_calls(tool_calls, &block)
      end

      private

      def build_request_body(messages, tools)
        { model: @model, messages:, stream: true, tools:, tool_choice: "auto" }
      end

      def handle_event(event, tool_calls, &block)
        delta = event.dig("choices", 0, "delta") || {}

        block.call(type: "saying", text: delta["content"]) if delta["content"]

        accumulate_tool_calls(delta["tool_calls"], tool_calls) if delta["tool_calls"]
      end

      def accumulate_tool_calls(incoming_tool_calls, tool_calls)
        incoming_tool_calls.each do |tool_call|
          index = tool_call["index"]
          tool_calls[index] ||= { id: nil, name: nil, args: String.new }
          tool_calls[index][:id] ||= tool_call["id"]
          tool_calls[index][:name] ||= tool_call.dig("function", "name")
          tool_calls[index][:args] << tool_call.dig("function", "arguments").to_s
        end
      end

      def stream(body)
        @http.post(@url, headers: headers, body:) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(::Net::HTTPSuccess)

          read_sse_stream(response) { |event| yield event }
        end
      end

      def headers
        { "Authorization" => "Bearer #{@api_key}" }
      end

      def read_sse_stream(response)
        buffer = String.new

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n"))
            line = buffer.slice!(0, index + 1).strip
            next unless line.start_with?("data: ") && line != "data: [DONE]"

            yield JSON.parse(line.delete_prefix("data: "))
          end
        end
      end

      def finalize_tool_calls(tool_calls, &block)
        tool_calls.values.map do |tool_call|
          result = {
            id: tool_call[:id],
            name: tool_call[:name],
            arguments: JSON.parse(tool_call[:args])
          }
          block.call(type: "tool_call", **result)
          result
        end
      end
    end
  end
end
