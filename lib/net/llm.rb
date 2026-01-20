# frozen_string_literal: true

require "net/hippie"
require "json"

require_relative "llm/version"
require_relative "llm/openai"
require_relative "llm/ollama"
require_relative "llm/claude"
require_relative "llm/anthropic"
require_relative "llm/vertex_ai"

module Net
  module Llm
    class Error < StandardError; end

    def self.http
      @http ||= Net::Hippie::Client.new(
        read_timeout: 3600,
        open_timeout: 10
      )
    end
  end
end
