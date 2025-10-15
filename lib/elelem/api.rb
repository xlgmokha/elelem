# frozen_string_literal: true

require "net/llm"

module Elelem
  class Api
    attr_reader :configuration, :client

    def initialize(configuration)
      @configuration = configuration
      @client = Net::Llm::Ollama.new(
        host: configuration.host,
        model: configuration.model
      )
    end

    def chat(messages, &block)
      tools = configuration.tools.to_h
      client.chat(messages, tools) do |chunk|
        normalized = normalize_ollama_response(chunk)
        block.call(normalized) if normalized
      end
    end

    private

    def normalize_ollama_response(chunk)
      if chunk["done"]
        finish_reason = chunk["done_reason"] || "stop"
        return { "done" => true, "finish_reason" => finish_reason }
      end

      message = chunk["message"]
      return nil unless message

      result = {}
      result["role"] = message["role"] if message["role"]
      result["content"] = message["content"] if message["content"]
      result["reasoning"] = message["thinking"] if message["thinking"]
      result["tool_calls"] = message["tool_calls"] if message["tool_calls"]

      result.empty? ? nil : result
    end
  end
end
