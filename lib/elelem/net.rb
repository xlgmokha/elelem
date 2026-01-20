# frozen_string_literal: true

require "net/hippie"
require "json"

require_relative "net/ollama"
require_relative "net/openai"
require_relative "net/claude"

module Elelem
  module Net
    def self.http
      @http ||= ::Net::Hippie::Client.new(read_timeout: 3600, open_timeout: 10)
    end
  end
end
