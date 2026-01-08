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
      provider = options[:provider]
      model = options[:model]
      say "Agent (#{provider})", :green
      agent = Agent.new(provider, model, Toolbox.new)
      agent.repl
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
