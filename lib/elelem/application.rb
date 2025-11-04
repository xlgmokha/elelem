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
    method_option :token,
                  aliases: "--token",
                  type: :string,
                  desc: "Ollama token",
                  default: ENV.fetch("OLLAMA_API_KEY", nil)

    def chat(*)
      configuration = Configuration.new(
        host: options[:host],
        model: options[:model],
        token: options[:token],
      )
      say "Agent (#{configuration.model})", :green
      say configuration.tools.banner.to_s, :green

      agent = Agent.new(configuration)
      agent.repl
    end

    desc "version", "The version of this CLI"
    def version
      say "v#{Elelem::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
