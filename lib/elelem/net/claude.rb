# frozen_string_literal: true

module Elelem
  module Net
    class Claude
      def self.anthropic(model:, api_key:, http: Elelem::Net.http)
        new(
          endpoint: "https://api.anthropic.com/v1/messages",
          headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
          model:,
          http:
        )
      end

      def self.vertex(model:, project:, region: "us-east5", http: Elelem::Net.http)
        new(
          endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project}/locations/#{region}/publishers/anthropic/models/#{model}:rawPredict",
          headers: -> { { "Authorization" => "Bearer #{`gcloud auth application-default print-access-token`.strip}" } },
          version: "vertex-2023-10-16",
          http:
        )
      end

      def initialize(endpoint:, headers:, model:, version: nil, http: Elelem::Net.http)
        @endpoint, @headers_src, @model, @version, @http = endpoint, headers, model, version, http
      end

      def fetch(messages, tools = [], &block)
        system, msgs = extract_system(messages)
        tool_calls = []

        stream(msgs, system, tools) do |event|
          case event["type"]
          when "content_block_start"
            if event.dig("content_block", "type") == "tool_use"
              tool_calls << { id: event.dig("content_block", "id"), name: event.dig("content_block", "name"), args: "" }
            end
          when "content_block_delta"
            case event.dig("delta", "type")
            when "text_delta"
              block.call(content: event.dig("delta", "text"), thinking: nil)
            when "thinking_delta"
              block.call(content: nil, thinking: event.dig("delta", "thinking"))
            when "input_json_delta"
              tool_calls.last[:args] += event.dig("delta", "partial_json").to_s if tool_calls.any?
            end
          when "message_stop"
            tool_calls.each { |tool_call| tool_call[:arguments] = begin; JSON.parse(tool_call.delete(:args)); rescue; {}; end }
          end
        end
        tool_calls
      end

      private

      def headers = @headers_src.respond_to?(:call) ? @headers_src.call : @headers_src

      def stream(messages, system, tools, &block)
        body = { max_tokens: 64000, messages:, stream: true }
        body[:model] = @model if @model
        body[:anthropic_version] = @version if @version
        body[:system] = system if system
        body[:tools] = unwrap_tools(tools) unless tools.empty?

        @http.post(@endpoint, headers:, body:) do |res|
          raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(::Net::HTTPSuccess)
          buf = ""
          res.read_body do |chunk|
            buf += chunk
            while (i = buf.index("\n\n"))
              parse_sse(buf.slice!(0, i + 2))&.then { |data| block.call(data) }
            end
          end
        end
      end

      def parse_sse(raw)
        data = raw.lines.find { |l| l.start_with?("data: ") }&.then { |l| l[6..] }
        data && data != "[DONE]" ? JSON.parse(data) : nil
      end

      def extract_system(messages)
        sys = messages.find { |m| m[:role] == "system" || m["role"] == "system" }
        [sys && (sys[:content] || sys["content"]), normalize(messages.reject { |m| m[:role] == "system" || m["role"] == "system" })]
      end

      def normalize(messages)
        messages.map do |m|
          role, tool_calls = m[:role] || m["role"], m[:tool_calls] || m["tool_calls"]

          if role == "tool"
            { role: "user", content: [{ type: "tool_result", tool_use_id: m[:tool_call_id] || m["tool_call_id"], content: m[:content] || m["content"] }] }
          elsif role == "assistant" && tool_calls&.any?
            content = []
            text = m[:content] || m["content"]
            content << { type: "text", text: } if text && !text.empty?
            tool_calls.each do |tool_call|
              fn = tool_call[:function] || tool_call["function"] || {}
              args = fn[:arguments] || fn["arguments"]
              content << { type: "tool_use", id: tool_call[:id] || tool_call["id"], name: fn[:name] || fn["name"] || tool_call[:name] || tool_call["name"], input: args.is_a?(String) ? (JSON.parse(args) rescue {}) : (args || {}) }
            end
            { role: "assistant", content: }
          else
            m
          end
        end
      end

      def unwrap_tools(tools)
        tools.map do |tool|
          {
            name: tool.dig(:function, :name),
            description: tool.dig(:function, :description),
            input_schema: tool.dig(:function, :parameters)
          }
        end
      end
    end
  end
end
