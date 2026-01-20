# frozen_string_literal: true

require "net/hippie"
require "json"

require_relative "llm/ollama"
require_relative "llm/openai"
require_relative "llm/claude"

module Net
  module Llm
    def self.http
      @http ||= Net::Hippie::Client.new(read_timeout: 3600, open_timeout: 10)
    end
  end
end
