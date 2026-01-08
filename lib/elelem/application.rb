# frozen_string_literal: true

module Elelem
  class Application < Thor
    PROVIDERS = %w[ollama anthropic openai vertex-ai].freeze

    desc "chat", "Start the REPL"
    method_option :provider,
                  aliases: "-p",
                  type: :string,
                  desc: "LLM provider (#{PROVIDERS.join(', ')})",
                  default: ENV.fetch("ELELEM_PROVIDER", "ollama")
    method_option :model,
                  aliases: "-m",
                  type: :string,
                  desc: "Model name (uses provider default if not specified)"
    def chat(*)
      client = build_client
      say "Agent (#{options[:provider]}/#{client.model})", :green
      agent = Agent.new(client, Toolbox.new)
      agent.repl
    end

    private

    def build_client
      model_opts = options[:model] ? { model: options[:model] } : {}

      case options[:provider]
      when "ollama"     then Net::Llm::Ollama.new(**model_opts)
      when "anthropic"  then Net::Llm::Anthropic.new(**model_opts)
      when "openai"     then Net::Llm::OpenAI.new(**model_opts)
      when "vertex-ai"  then Net::Llm::VertexAI.new(**model_opts)
      else
        raise Error, "Unknown provider: #{options[:provider]}. Use: #{PROVIDERS.join(', ')}"
      end
    end

    desc "files", "Generate CXML of the files"
    def files
      puts '<documents>'
      $stdin.read.split("\n").map(&:strip).reject(&:empty?).each_with_index do |file, i|
        next unless File.file?(file)

        puts "  <document index=\"#{i + 1}\">"
        puts "    <source><![CDATA[#{file}]]></source>"
        puts "    <document_content><![CDATA[#{File.read(file)}]]></document_content>"
        puts "  </document>"
      end
      puts '</documents>'
    end

    desc "version", "The version of this CLI"
    def version
      say "v#{Elelem::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
