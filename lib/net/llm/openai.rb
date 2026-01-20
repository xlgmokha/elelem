# frozen_string_literal: true

module Net
  module Llm
    class OpenAI
      attr_reader :api_key, :base_url, :model, :http

      def initialize(api_key: ENV.fetch("OPENAI_API_KEY"), base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"), model: "gpt-4o-mini", http: Net::Llm.http)
        @api_key = api_key
        @base_url = base_url
        @model = model
        @http = http
      end

      def chat(messages, tools)
        handle_response(http.post(
          "#{base_url}/chat/completions",
          headers: headers,
          body: { model: model, messages: messages, tools: tools, tool_choice: "auto" }
        ))
      end

      def fetch(messages, tools = [], &block)
        if block_given?
          fetch_streaming(messages, tools, &block)
        else
          fetch_non_streaming(messages, tools)
        end
      end

      def models
        handle_response(http.get("#{base_url}/models", headers: headers))
      end

      def embeddings(input, model: "text-embedding-ada-002")
        handle_response(http.post(
          "#{base_url}/embeddings",
          headers: headers,
          body: { model: model, input: input },
        ))
      end

      private

      def headers
        { "Authorization" => Net::Hippie.bearer_auth(api_key) }
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          { "code" => response.code, "body" => response.body }
        end
      end

      def fetch_non_streaming(messages, tools)
        body = { model: model, messages: messages }
        body[:tools] = tools unless tools.empty?
        body[:tool_choice] = "auto" unless tools.empty?

        result = handle_response(http.post("#{base_url}/chat/completions", headers: headers, body: body))
        return result if result["code"]

        msg = result.dig("choices", 0, "message") || {}
        {
          type: :complete,
          content: msg["content"],
          thinking: nil,
          tool_calls: normalize_tool_calls(msg["tool_calls"]),
          stop_reason: map_stop_reason(result.dig("choices", 0, "finish_reason"))
        }
      end

      def fetch_streaming(messages, tools, &block)
        body = { model: model, messages: messages, stream: true }
        body[:tools] = tools unless tools.empty?
        body[:tool_choice] = "auto" unless tools.empty?

        content = ""
        tool_calls = {}
        stop_reason = :end_turn

        http.post("#{base_url}/chat/completions", headers: headers, body: body) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

          buffer = ""
          response.read_body do |chunk|
            buffer += chunk

            while (line = extract_line(buffer))
              next if line.empty? || !line.start_with?("data: ")

              data = line[6..]
              break if data == "[DONE]"

              json = JSON.parse(data)
              delta = json.dig("choices", 0, "delta") || {}

              if delta["content"]
                content += delta["content"]
                block.call({ type: :delta, content: delta["content"], thinking: nil, tool_calls: nil })
              end

              if delta["tool_calls"]
                delta["tool_calls"].each do |tc|
                  idx = tc["index"]
                  tool_calls[idx] ||= { id: nil, name: nil, arguments_json: "" }
                  tool_calls[idx][:id] = tc["id"] if tc["id"]
                  tool_calls[idx][:name] = tc.dig("function", "name") if tc.dig("function", "name")
                  tool_calls[idx][:arguments_json] += tc.dig("function", "arguments") || ""
                end
              end

              if json.dig("choices", 0, "finish_reason")
                stop_reason = map_stop_reason(json.dig("choices", 0, "finish_reason"))
              end
            end
          end
        end

        final_tool_calls = tool_calls.values.map do |tc|
          args = begin
            JSON.parse(tc[:arguments_json])
          rescue
            {}
          end
          { id: tc[:id], name: tc[:name], arguments: args }
        end

        block.call({
          type: :complete,
          content: content,
          thinking: nil,
          tool_calls: final_tool_calls,
          stop_reason: stop_reason
        })
      end

      def extract_line(buffer)
        line_end = buffer.index("\n")
        return nil unless line_end

        line = buffer[0...line_end]
        buffer.replace(buffer[(line_end + 1)..] || "")
        line
      end

      def normalize_tool_calls(tool_calls)
        return [] if tool_calls.nil? || tool_calls.empty?

        tool_calls.map do |tc|
          args = tc.dig("function", "arguments")
          {
            id: tc["id"],
            name: tc.dig("function", "name"),
            arguments: args.is_a?(String) ? (JSON.parse(args) rescue {}) : (args || {})
          }
        end
      end

      def map_stop_reason(reason)
        case reason
        when "stop" then :end_turn
        when "tool_calls" then :tool_use
        when "length" then :max_tokens
        else :end_turn
        end
      end
    end
  end
end
