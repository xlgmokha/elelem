# frozen_string_literal: true

Elelem::Providers.register(:ollama) do
  Elelem::Net::Ollama.new(
    model: ENV.fetch("OLLAMA_MODEL", "gpt-oss:latest"),
    host: ENV.fetch("OLLAMA_HOST", "localhost:11434")
  )
end
