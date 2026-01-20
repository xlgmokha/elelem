# frozen_string_literal: true

module Elelem
  module Net
    class Claude
      def initialize(endpoint:, headers:, model: nil, version: nil, http: Elelem::Net.http)
        @endpoint, @headers_src, @model, @version, @http = endpoint, headers, model, version, http
      end

      def self.anthropic(model:, api_key: ENV.fetch("ANTHROPIC_API_KEY"), http: Elelem::Net.http)
        new(endpoint: "https://api.anthropic.com/v1/messages",
            headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
            model:, http:)
      end

      def self.vertex(model:, project: ENV.fetch("GOOGLE_CLOUD_PROJECT"), region: ENV.fetch("GOOGLE_CLOUD_REGION", "us-east5"), http: Elelem::Net.http)
        new(endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project}/locations/#{region}/publishers/anthropic/models/#{model}:rawPredict",
            headers: -> { { "Authorization" => "Bearer #{`gcloud auth application-default print-access-token`.strip}" } },
            version: "vertex-2023-10-16", http:)
      end

      def fetch(messages, tools = [], &block)
        system, msgs = extract_system(messages)
        content, thinking, tool_calls = "", "", []

        stream(msgs, system, tools) do |event|
          case event["type"]
          when "content_block_start"
            if event.dig("content_block", "type") == "tool_use"
              tool_calls << { id: event.dig("content_block", "id"), name: event.dig("content_block", "name"), args: "" }
            end
          when "content_block_delta"
            case event.dig("delta", "type")
            when "text_delta"
              text = event.dig("delta", "text")
              content += text
              block.call(type: :delta, content: text, thinking: nil, tool_calls: nil)
            when "thinking_delta"
              text = event.dig("delta", "thinking")
              thinking += text.to_s
              block.call(type: :delta, content: nil, thinking: text, tool_calls: nil)
            when "input_json_delta"
              tool_calls.last[:args] += event.dig("delta", "partial_json").to_s if tool_calls.any?
            end
          when "message_stop"
            tool_calls.each do |tc|
              tc[:arguments] = begin; JSON.parse(tc.delete(:args)); rescue; {}; end
            end
            block.call(type: :complete, content:, thinking: (thinking unless thinking.empty?), tool_calls:)
          end
        end
      end

      private

      def headers = @headers_src.respond_to?(:call) ? @headers_src.call : @headers_src

      def stream(messages, system, tools, &block)
        body = { max_tokens: 64000, messages:, stream: true }
        body[:model] = @model if @model
        body[:anthropic_version] = @version if @version
        body[:system] = system if system
        body[:tools] = tools.map { |t| t[:function] ? { name: t[:function][:name], description: t[:function][:description], input_schema: t[:function][:parameters] } : t } unless tools.empty?

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
          role, tcs = m[:role] || m["role"], m[:tool_calls] || m["tool_calls"]

          if role == "tool"
            { role: "user", content: [{ type: "tool_result", tool_use_id: m[:tool_call_id] || m["tool_call_id"], content: m[:content] || m["content"] }] }
          elsif role == "assistant" && tcs&.any?
            content = []
            text = m[:content] || m["content"]
            content << { type: "text", text: } if text && !text.empty?
            tcs.each do |tc|
              fn = tc[:function] || tc["function"] || {}
              args = fn[:arguments] || fn["arguments"]
              content << { type: "tool_use", id: tc[:id] || tc["id"], name: fn[:name] || fn["name"] || tc[:name] || tc["name"], input: args.is_a?(String) ? (JSON.parse(args) rescue {}) : (args || {}) }
            end
            { role: "assistant", content: }
          else
            m
          end
        end
      end
    end
  end
end
