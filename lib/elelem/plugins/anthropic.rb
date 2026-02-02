# frozen_string_literal: true

Elelem::Providers.register(:anthropic) do
  Elelem::Net::Claude.anthropic(
    model: ENV.fetch("ANTHROPIC_MODEL", "claude-opus-4-5-20250514"),
    api_key: ENV.fetch("ANTHROPIC_API_KEY")
  )
end
