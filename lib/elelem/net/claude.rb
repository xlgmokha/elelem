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
          model:,
          version: "vertex-2023-10-16",
          http:
        )
      end

      def initialize(endpoint:, headers:, model:, version: nil, http: Elelem::Net.http)
        @endpoint = endpoint
        @headers_source = headers
        @model = model
        @version = version
        @http = http
      end

      def fetch(messages, tools = [], &block)
        system_prompt, normalized_messages = extract_system(messages)
        tool_calls = []

        stream(normalized_messages, system_prompt, tools) do |event|
          handle_event(event, tool_calls, &block)
        end

        finalize_tool_calls(tool_calls)
      end

      private

      def headers
        @headers_source.respond_to?(:call) ? @headers_source.call : @headers_source
      end

      def handle_event(event, tool_calls, &block)
        case event["type"]
        when "content_block_start"
          handle_content_block_start(event, tool_calls)
        when "content_block_delta"
          handle_content_block_delta(event, tool_calls, &block)
        end
      end

      def handle_content_block_start(event, tool_calls)
        content_block = event["content_block"]
        return unless content_block["type"] == "tool_use"

        tool_calls << {
          id: content_block["id"],
          name: content_block["name"],
          args: String.new
        }
      end

      def handle_content_block_delta(event, tool_calls, &block)
        delta = event["delta"]

        case delta["type"]
        when "text_delta"
          block.call(content: delta["text"], thinking: nil)
        when "thinking_delta"
          block.call(content: nil, thinking: delta["thinking"])
        when "input_json_delta"
          tool_calls.last[:args] << delta["partial_json"].to_s if tool_calls.any?
        end
      end

      def finalize_tool_calls(tool_calls)
        tool_calls.each do |tool_call|
          args = tool_call.delete(:args)
          tool_call[:arguments] = args.empty? ? {} : JSON.parse(args)
        end
      end

      def stream(messages, system_prompt, tools)
        body = build_request_body(messages, system_prompt, tools)

        @http.post(@endpoint, headers:, body:) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(::Net::HTTPSuccess)

          read_sse_stream(response) { |event| yield event }
        end
      end

      def build_request_body(messages, system_prompt, tools)
        body = { max_tokens: 64000, messages:, stream: true }
        body[:model] = @model unless @version
        body[:anthropic_version] = @version if @version
        body[:system] = system_prompt if system_prompt
        body[:tools] = unwrap_tools(tools) unless tools.empty?
        body
      end

      def read_sse_stream(response)
        buffer = String.new

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n\n"))
            raw_event = buffer.slice!(0, index + 2)
            event = parse_sse(raw_event)
            yield event if event
          end
        end
      end

      def parse_sse(raw)
        line = raw.lines.find { |l| l.start_with?("data: ") }
        return nil unless line

        data = line.delete_prefix("data: ").strip
        return nil if data == "[DONE]"

        JSON.parse(data)
      end

      def extract_system(messages)
        system_messages, other_messages = messages.partition { |message| message[:role] == "system" }
        system_content = system_messages.first&.dig(:content)
        [system_content, normalize(other_messages)]
      end

      def normalize(messages)
        messages.map { |message| normalize_message(message) }
      end

      def normalize_message(message)
        case message[:role]
        when "tool"
          tool_result_message(message)
        when "assistant"
          message[:tool_calls]&.any? ? assistant_with_tools_message(message) : message
        else
          message
        end
      end

      def tool_result_message(message)
        {
          role: "user",
          content: [{
            type: "tool_result",
            tool_use_id: message[:tool_call_id],
            content: message[:content]
          }]
        }
      end

      def assistant_with_tools_message(message)
        text_content = build_text_content(message[:content])
        tool_content = build_tool_content(message[:tool_calls])

        { role: "assistant", content: text_content + tool_content }
      end

      def build_text_content(content)
        return [] if content.to_s.empty?

        [{ type: "text", text: content }]
      end

      def build_tool_content(tool_calls)
        tool_calls.map do |tool_call|
          {
            type: "tool_use",
            id: tool_call[:id],
            name: tool_call[:name],
            input: tool_call[:arguments]
          }
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
