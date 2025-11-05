# frozen_string_literal: true

module Elelem
  class Application < Thor
    desc "chat", "Start the REPL"
    method_option :host,
                  aliases: "--host",
                  type: :string,
                  desc: "Ollama host",
                  default: ENV.fetch("OLLAMA_HOST", "localhost:11434")
    method_option :model,
                  aliases: "--model",
                  type: :string,
                  desc: "Ollama model",
                  default: ENV.fetch("OLLAMA_MODEL", "gpt-oss")

    def chat(*)
      client = Net::Llm::Ollama.new(
        host: options[:host],
        model: options[:model],
      )
      say "Agent (#{options[:model]})", :green
      agent = Agent.new(client)

      agent.repl
    end

    desc "version", "The version of this CLI"
    def version
      say "v#{Elelem::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
