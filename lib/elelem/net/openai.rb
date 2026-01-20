# frozen_string_literal: true

module Elelem
  module Net
    class OpenAI
      def initialize(model:, api_key: ENV.fetch("OPENAI_API_KEY"), base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"), http: Elelem::Net.http)
        @url = "#{base_url}/chat/completions"
        @model, @api_key, @http = model, api_key, http
      end

      def fetch(messages, tools = [], &block)
        content, tool_calls, stop = "", {}, :end_turn
        body = { model: @model, messages:, stream: true }
        body.merge!(tools:, tool_choice: "auto") unless tools.empty?

        stream(body) do |json|
          delta = json.dig("choices", 0, "delta") || {}

          if (text = delta["content"])
            content += text
            block.call(type: :delta, content: text, thinking: nil, tool_calls: nil)
          end

          delta["tool_calls"]&.each do |tc|
            idx = tc["index"]
            tool_calls[idx] ||= { id: nil, name: nil, args: "" }
            tool_calls[idx][:id] ||= tc["id"]
            tool_calls[idx][:name] ||= tc.dig("function", "name")
            tool_calls[idx][:args] += tc.dig("function", "arguments").to_s
          end

          stop = json.dig("choices", 0, "finish_reason")&.to_sym || stop
        end

        block.call(type: :complete, content:, thinking: nil, tool_calls: finalize_tools(tool_calls))
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

      def finalize_tools(tcs)
        tcs.values.map do |tc|
          args = begin; JSON.parse(tc[:args]); rescue; {}; end
          { id: tc[:id], name: tc[:name], arguments: args }
        end
      end
    end
  end
end
