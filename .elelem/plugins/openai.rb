# frozen_string_literal: true

Elelem::Providers.register(:openai) do
  Elelem::Net::OpenAI.new(
    model: ENV.fetch("OPENAI_MODEL", "gpt-4o"),
    api_key: ENV.fetch("OPENAI_API_KEY")
  )
end
