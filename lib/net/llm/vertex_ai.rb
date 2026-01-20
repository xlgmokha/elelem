# frozen_string_literal: true

module Net
  module Llm
    class VertexAI
      attr_reader :project_id, :region, :model

      def initialize(project_id: ENV.fetch("GOOGLE_CLOUD_PROJECT"), region: ENV.fetch("GOOGLE_CLOUD_REGION", "us-east5"), model: "claude-opus-4-5@20251101", http: Net::Llm.http)
        @project_id = project_id
        @region = region
        @model = model
        @handler = build_handler(http)
      end

      def messages(...) = @handler.messages(...)
      def fetch(...) = @handler.fetch(...)

      private

      def build_handler(http)
        if model.start_with?("claude-")
          Claude.new(
            endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project_id}/locations/#{region}/publishers/anthropic/models/#{model}:rawPredict",
            headers: -> { { "Authorization" => "Bearer #{access_token}" } },
            http: http,
            anthropic_version: "vertex-2023-10-16"
          )
        else
          raise NotImplementedError, "Model '#{model}' is not yet supported. Only Claude models (claude-*) are currently implemented."
        end
      end

      def access_token
        ENV.fetch("GOOGLE_OAUTH_ACCESS_TOKEN") do
          `gcloud auth application-default print-access-token`.strip
        end
      end
    end
  end
end
