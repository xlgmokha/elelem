# frozen_string_literal: true

module Elelem
  # Registry for LLM provider plugins.
  #
  # Providers must implement:
  #
  #   fetch(messages, tools = []) { |event| ... } -> Array<tool_calls>
  #
  # Messages (OpenAI format):
  #   { role: "system"|"user"|"assistant", content: "..." }
  #   { role: "tool", tool_call_id: "...", content: "..." }
  #
  # Tools (OpenAI format):
  #   { type: "function", function: { name:, description:, parameters: } }
  #
  # Streaming events (yield to block):
  #   { type: "saying", text: "..." }
  #   { type: "thinking", text: "..." }
  #   { type: "tool_call", id:, name:, arguments: }
  #
  # Returns: [{ id:, name:, arguments: }, ...]
  #
  # Example:
  #
  #   Elelem::Providers.register(:gemini) do
  #     MyGeminiClient.new(model: ENV.fetch("GEMINI_MODEL", "gemini-pro"))
  #   end
  #
  module Providers
    def self.register(name, &factory)
      registry[name.to_s] = factory
    end

    def self.build(name)
      Plugins.load! if registry.empty?
      registry.fetch(name.to_s).call
    end

    def self.names
      registry.keys
    end

    def self.registry
      @registry ||= {}
    end
  end
end
