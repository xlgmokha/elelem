# frozen_string_literal: true

module Elelem
  class Application < Thor
    desc 'chat', 'Start the REPL'
    method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
    method_option :host, aliases: '--host', type: :string, desc: 'Ollama host', default: ENV.fetch('OLLAMA_HOST', 'localhost:11434')
    method_option :model, aliases: '--model', type: :string, desc: 'Ollama model', default: ENV.fetch('OLLAMA_MODEL', 'gpt-oss')
    method_option :token, aliases: '--token', type: :string, desc: 'Ollama token', default: ENV.fetch('OLLAMA_API_KEY', nil)
    method_option :debug, aliases: '--debug', type: :boolean, desc: 'Debug mode', default: ENV.fetch('DEBUG', '0') == '1'
    def chat(*)
      if options[:help]
        invoke :help, ['chat']
      else
        agent = Agent.new(Configuration.new(
          host: options[:host],
          model: options[:model],
          token: options[:token],
          debug: options[:debug],
        ))
        agent.repl
      end
    end

    desc 'version', 'spandx version'
    def version
      puts "v#{Spandx::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
