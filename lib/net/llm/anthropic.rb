# frozen_string_literal: true

module Net
  module Llm
    class Anthropic
      attr_reader :api_key, :model

      def initialize(api_key: ENV.fetch("ANTHROPIC_API_KEY"), model: "claude-sonnet-4-20250514", http: Net::Llm.http)
        @api_key = api_key
        @model = model
        @claude = Claude.new(
          endpoint: "https://api.anthropic.com/v1/messages",
          headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
          model: model,
          http: http
        )
      end

      def messages(...) = @claude.messages(...)
      def fetch(...) = @claude.fetch(...)
    end
  end
end
