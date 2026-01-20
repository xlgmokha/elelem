# frozen_string_literal: true

module Net
  module Llm
    class Ollama
      attr_reader :host, :model, :http

      def initialize(host: ENV.fetch("OLLAMA_HOST", "localhost:11434"), model: "gpt-oss", http: Net::Llm.http)
        @host = host
        @model = model
        @http = http
      end

      def chat(messages, tools = [], &block)
        payload = { model: model, messages: messages, stream: block_given? }
        payload[:tools] = tools unless tools.empty?

        execute(build_url("/api/chat"), payload, &block)
      end

      def fetch(messages, tools = [], &block)
        content = ""
        thinking = ""
        tool_calls = []

        if block_given?
          chat(messages, tools) do |chunk|
            msg = chunk["message"] || {}
            delta_content = msg["content"]
            delta_thinking = msg["thinking"]

            content += delta_content if delta_content
            thinking += delta_thinking if delta_thinking
            tool_calls += normalize_tool_calls(msg["tool_calls"]) if msg["tool_calls"]

            if chunk["done"]
              block.call({
                type: :complete,
                content: content,
                thinking: thinking.empty? ? nil : thinking,
                tool_calls: tool_calls,
                stop_reason: map_stop_reason(chunk["done_reason"])
              })
            else
              block.call({
                type: :delta,
                content: delta_content,
                thinking: delta_thinking,
                tool_calls: nil
              })
            end
          end
        else
          result = chat(messages, tools)
          msg = result["message"] || {}
          {
            type: :complete,
            content: msg["content"],
            thinking: msg["thinking"],
            tool_calls: normalize_tool_calls(msg["tool_calls"]),
            stop_reason: map_stop_reason(result["done_reason"])
          }
        end
      end

      def generate(prompt, &block)
        execute(build_url("/api/generate"), {
          model: model,
          prompt: prompt,
          stream: block_given?
        }, &block)
      end

      def embeddings(input)
        post_request(build_url("/api/embed"), { model: model, input: input })
      end

      def tags
        get_request(build_url("/api/tags"))
      end

      def show(name)
        post_request(build_url("/api/show"), { name: name })
      end

      private

      def execute(url, payload, &block)
        if block_given?
          stream_request(url, payload, &block)
        else
          post_request(url, payload)
        end
      end

      def build_url(path)
        base = host.start_with?("http://", "https://") ? host : "http://#{host}"
        "#{base}#{path}"
      end

      def get_request(url)
        handle_response(http.get(url))
      end

      def post_request(url, payload)
        handle_response(http.post(url, body: payload))
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          {
            "code" => response.code,
            "body" => response.body
          }
        end
      end

      def stream_request(url, payload, &block)
        http.post(url, body: payload) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

          buffer = ""
          response.read_body do |chunk|
            buffer += chunk

            while (message = extract_message(buffer))
              next if message.empty?

              json = JSON.parse(message)
              block.call(json)

              break if json["done"]
            end
          end
        end
      end

      def extract_message(buffer)
        message_end = buffer.index("\n")
        return nil unless message_end

        message = buffer[0...message_end]
        buffer.replace(buffer[(message_end + 1)..-1] || "")
        message
      end

      def normalize_tool_calls(tool_calls)
        return [] if tool_calls.nil? || tool_calls.empty?

        tool_calls.map do |tc|
          {
            id: tc["id"] || tc.dig("function", "id"),
            name: tc.dig("function", "name"),
            arguments: tc.dig("function", "arguments") || {}
          }
        end
      end

      def map_stop_reason(reason)
        case reason
        when "stop" then :end_turn
        when "tool_calls", "tool_use" then :tool_use
        when "length" then :max_tokens
        else :end_turn
        end
      end
    end
  end
end
