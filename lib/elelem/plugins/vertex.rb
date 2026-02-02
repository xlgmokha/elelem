# frozen_string_literal: true

Elelem::Providers.register(:vertex) do
  Elelem::Net::Claude.vertex(
    model: ENV.fetch("VERTEX_MODEL", "claude-opus-4-5@20251101"),
    project: ENV.fetch("GOOGLE_CLOUD_PROJECT"),
    region: ENV.fetch("GOOGLE_CLOUD_REGION", "us-east5")
  )
end
