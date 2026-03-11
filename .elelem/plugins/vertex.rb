# frozen_string_literal: true

Elelem::Providers.register(:vertex) do
  model = ENV.fetch("VERTEX_MODEL", "claude-opus-4-5@20251101")
  project = ENV.fetch("GOOGLE_CLOUD_PROJECT")
  region = ENV.fetch("GOOGLE_CLOUD_REGION", "us-east5")
  Elelem::Net::Claude.new(
    endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project}/locations/#{region}/publishers/anthropic/models/#{model}:rawPredict",
    headers: -> { { "Authorization" => "Bearer #{`gcloud auth application-default print-access-token`.strip}" } },
    model: model,
    version: "vertex-2023-10-16",
  )
end
