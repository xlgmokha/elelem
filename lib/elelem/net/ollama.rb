# frozen_string_literal: true

module Elelem
  module Net
    class Ollama
      def initialize(
        model:,
        host: "localhost:11434",
        think: "medium",
        keep_alive: "5m",
        options: {},
        params: {},
        http: Elelem::Net.http
      )
        @url = normalize_url(host)
        @model = model
        @think = think
        @keep_alive = keep_alive
        @options = options
        @params = params
        @http = http
      end

      def fetch(messages, tools = [], &block)
        tool_calls = []
        body = build_request_body(messages, tools)

        stream(body) do |event|
          handle_event(event, tool_calls, &block)
        end

        tool_calls
      end

      private

      def normalize_url(host)
        base = host.start_with?("http") ? host : "http://#{host}"
        "#{base}/api/chat"
      end

      # POST /api/chat request body. Anything left unset uses the server or default.
=begin

  | Field              | Type                  | Notes                                                 |
  | ---                | ---                   | ---                                                   |
  | model              | string                │ required                                              │
  | messages           | array                 │ see below                                             │
  | tools              | array                 │ JSON tool schemas                                     │
  | stream             | bool                  │ NDJSON stream when true                               │
  | think              | bool or string        │ thinking models; "low"/"medium"/"high"                │
  | format             | "json" or JSON schema │ structured output                                     │
  | options            | object                │ model params, see below                               │
  | keep_alive         | duration              │ how long model stays resident, e.g. "5m", 0 to unload │
  | truncate           | bool                  │ truncate prompt to fit context                        │
  | shift              | bool                  │ shift context window instead of erroring when full    │
  | logprobs           | bool                  │ return token logprobs                                 │
  | top_logprobs       | int                   │ how many alternatives per token                       │
  | _debug_render_only | bool                  │ return rendered prompt without inference              │

  Message object

  | Field | Description |
  | ---- | --------- |
  | role | (system|user|assistant|tool) |
  | content | |
  | thinking | |
  | images | (base64 array, multimodal) |
  | tool_calls | |
  | tool_name | name of the tool that produced a tool message |

  Options

    Sampling:

    | Field | Description |
    | ---- | ---- |
    | seed | |
    | temperature | |
    | top_k | |
    | top_p | |
    | min_p | |
    | typical_p | |
    | num_predict | |
    | num_keep | |
    | stop (array) | |
    | repeat_last_n | |
    | repeat_penalty | |
    | presence_penalty | |
    | frequency_penalty | |

    Runner:

    | Field | Description |
    | ----- | ----------- |
    | num_ctx | |
    | num_batch | |
    | num_gpu | |
    | main_gpu | |
    | use_mmap | |
    | num_thread | |
    | draft_num_predict | |
=end
      def build_request_body(messages, tools)
        {
          model: @model,
          messages:,
          stream: true,
          tools: presence(tools),
          think: @think,
          keep_alive: @keep_alive,
          options: presence(@options)
        }.merge(@params).compact
      end

      def presence(value)
        value unless value.nil? || value.empty?
      end

      def handle_event(event, tool_calls, &block)
        message = event["message"] || {}

        unless event["done"]
          block.call(type: "saying", text: message["content"]) if message["content"]
          block.call(type: "thinking", text: message["thinking"]) if message["thinking"]
        end

        if message["tool_calls"]
          parsed = parse_tool_calls(message["tool_calls"])
          parsed.each { |tc| block.call(tc.merge(type: "doing")) }
          tool_calls.concat(parsed)
        end
      end

      def stream(body)
        @http.post(@url, body:) do |response|
          raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(::Net::HTTPSuccess)

          read_ndjson_stream(response) { |event| yield event }
        end
      end

      def read_ndjson_stream(response)
        buffer = String.new

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n"))
            line = buffer.slice!(0, index + 1)
            yield JSON.parse(line)
          end
        end
      end

      def parse_tool_calls(tool_calls)
        tool_calls.map do |tool_call|
          {
            id: tool_call["id"],
            name: tool_call.dig("function", "name"),
            arguments: tool_call.dig("function", "arguments") || {}
          }
        end
      end
    end
  end
end
