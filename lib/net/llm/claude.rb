# frozen_string_literal: true

module Net
  module Llm
    class Claude
      attr_reader :endpoint, :headers, :model, :http, :anthropic_version

      def initialize(endpoint:, headers:, http:, model: nil, anthropic_version: nil)
        @endpoint = endpoint
        @headers_source = headers
        @model = model
        @http = http
        @anthropic_version = anthropic_version
      end

      def headers
        @headers_source.respond_to?(:call) ? @headers_source.call : @headers_source
      end

      def messages(messages, system: nil, max_tokens: 64000, tools: nil, &block)
        payload = build_payload(messages, system, max_tokens, tools, block_given?)

        if block_given?
          stream_request(payload, &block)
        else
          post_request(payload)
        end
      end

      def fetch(messages, tools = [], &block)
        system_message, user_messages = extract_system_message(messages)
        anthropic_tools = tools.empty? ? nil : tools.map { |t| normalize_tool_for_anthropic(t) }

        if block_given?
          fetch_streaming(user_messages, anthropic_tools, system: system_message, &block)
        else
          fetch_non_streaming(user_messages, anthropic_tools, system: system_message)
        end
      end

      private

      def build_payload(messages, system, max_tokens, tools, stream)
        payload = { max_tokens: max_tokens, messages: messages, stream: stream }
        payload[:model] = model if model
        payload[:anthropic_version] = anthropic_version if anthropic_version
        payload[:system] = system if system
        payload[:tools] = tools if tools
        payload
      end

      def post_request(payload)
        handle_response(http.post(endpoint, headers: headers, body: payload))
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          { "code" => response.code, "body" => response.body }
        end
      end

      def stream_request(payload, &block)
        http.post(endpoint, headers: headers, body: payload) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

          buffer = ""
          response.read_body do |chunk|
            buffer += chunk

            while (event = extract_sse_event(buffer))
              next if event[:data].nil? || event[:data].empty?
              next if event[:data] == "[DONE]"

              json = JSON.parse(event[:data])
              block.call(json)

              break if json["type"] == "message_stop"
            end
          end
        end
      end

      def extract_sse_event(buffer)
        event_end = buffer.index("\n\n")
        return nil unless event_end

        event_data = buffer[0...event_end]
        buffer.replace(buffer[(event_end + 2)..] || "")

        event = {}
        event_data.split("\n").each do |line|
          if line.start_with?("event: ")
            event[:event] = line[7..]
          elsif line.start_with?("data: ")
            event[:data] = line[6..]
          elsif line == "data:"
            event[:data] = ""
          end
        end

        event
      end

      def extract_system_message(messages)
        system_msg = messages.find { |m| m[:role] == "system" || m["role"] == "system" }
        system_content = system_msg ? (system_msg[:content] || system_msg["content"]) : nil
        other_messages = messages.reject { |m| m[:role] == "system" || m["role"] == "system" }
        normalized_messages = normalize_messages_for_claude(other_messages)
        [system_content, normalized_messages]
      end

      def normalize_messages_for_claude(messages)
        messages.map do |msg|
          role = msg[:role] || msg["role"]
          tool_calls = msg[:tool_calls] || msg["tool_calls"]

          if role == "tool"
            {
              role: "user",
              content: [{
                type: "tool_result",
                tool_use_id: msg[:tool_call_id] || msg["tool_call_id"],
                content: msg[:content] || msg["content"]
              }]
            }
          elsif role == "assistant" && tool_calls&.any?
            content = []
            text = msg[:content] || msg["content"]
            content << { type: "text", text: text } if text && !text.empty?
            tool_calls.each do |tc|
              func = tc[:function] || tc["function"] || {}
              args = func[:arguments] || func["arguments"]
              input = args.is_a?(String) ? (JSON.parse(args) rescue {}) : (args || {})
              content << {
                type: "tool_use",
                id: tc[:id] || tc["id"],
                name: func[:name] || func["name"] || tc[:name] || tc["name"],
                input: input
              }
            end
            { role: "assistant", content: content }
          else
            msg
          end
        end
      end

      def fetch_non_streaming(messages, tools, system: nil)
        result = self.messages(messages, system: system, tools: tools)
        return result if result["code"]

        {
          type: :complete,
          content: extract_text_content(result["content"]),
          thinking: extract_thinking_content(result["content"]),
          tool_calls: extract_tool_calls(result["content"]),
          stop_reason: map_stop_reason(result["stop_reason"])
        }
      end

      def fetch_streaming(messages, tools, system: nil, &block)
        content = ""
        thinking = ""
        tool_calls = []
        stop_reason = :end_turn

        self.messages(messages, system: system, tools: tools) do |event|
          case event["type"]
          when "content_block_start"
            if event.dig("content_block", "type") == "tool_use"
              tool_calls << {
                id: event.dig("content_block", "id"),
                name: event.dig("content_block", "name"),
                arguments: {}
              }
            end
          when "content_block_delta"
            delta = event["delta"]
            case delta["type"]
            when "text_delta"
              text = delta["text"]
              content += text
              block.call({ type: :delta, content: text, thinking: nil, tool_calls: nil })
            when "thinking_delta"
              text = delta["thinking"]
              thinking += text if text
              block.call({ type: :delta, content: nil, thinking: text, tool_calls: nil })
            when "input_json_delta"
              if tool_calls.any?
                tool_calls.last[:arguments_json] ||= ""
                tool_calls.last[:arguments_json] += delta["partial_json"] || ""
              end
            end
          when "message_delta"
            stop_reason = map_stop_reason(event.dig("delta", "stop_reason"))
          when "message_stop"
            tool_calls.each do |tc|
              if tc[:arguments_json]
                tc[:arguments] = begin
                  JSON.parse(tc[:arguments_json])
                rescue
                  {}
                end
                tc.delete(:arguments_json)
              end
            end
            block.call({
              type: :complete,
              content: content,
              thinking: thinking.empty? ? nil : thinking,
              tool_calls: tool_calls,
              stop_reason: stop_reason
            })
          end
        end
      end

      def extract_text_content(content_blocks)
        return nil unless content_blocks

        content_blocks
          .select { |b| b["type"] == "text" }
          .map { |b| b["text"] }
          .join
      end

      def extract_thinking_content(content_blocks)
        return nil unless content_blocks

        thinking = content_blocks
          .select { |b| b["type"] == "thinking" }
          .map { |b| b["thinking"] }
          .join

        thinking.empty? ? nil : thinking
      end

      def extract_tool_calls(content_blocks)
        return [] unless content_blocks

        content_blocks
          .select { |b| b["type"] == "tool_use" }
          .map { |b| { id: b["id"], name: b["name"], arguments: b["input"] || {} } }
      end

      def normalize_tool_for_anthropic(tool)
        if tool[:function]
          { name: tool[:function][:name], description: tool[:function][:description], input_schema: tool[:function][:parameters] }
        else
          tool
        end
      end

      def map_stop_reason(reason)
        case reason
        when "end_turn" then :end_turn
        when "tool_use" then :tool_use
        when "max_tokens" then :max_tokens
        else :end_turn
        end
      end
    end
  end
end
