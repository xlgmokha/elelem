# frozen_string_literal: true

require "elelem"

module Elelem
  class CLI
    def initialize(args)
      @provider = "ollama"
      @args = parse(args)
    end

    def run
      command = @args.shift || "chat"
      send(command.tr("-", "_"))
    rescue NoMethodError
      abort "Unknown command: #{command}"
    end

    private

    def parse(args)
      @parser = OptionParser.new do |o|
        o.banner = "Usage: elelem [command] [options] [args]"
        o.separator "\nCommands:"
        o.separator "  chat              Interactive REPL (default)"
        o.separator "  ask <prompt>      One-shot query (reads stdin if piped)"
        o.separator "  files             Output files as XML (no options)"
        o.separator "  help              Show this help"
        o.separator "\nOptions:"
        o.on("-p", "--provider NAME", "ollama, anthropic, vertex, openai") { |p| @provider = p }
        o.on("-h", "--help") { puts o; exit }
      end
      @parser.parse!(args)
    end

    def help
      puts @parser
    end

    def chat
      Elelem.start(provider: @provider)
    end

    def ask
      abort "Usage: elelem ask <prompt>" if @args.empty?
      prompt = @args.join(" ")
      prompt = "#{prompt}\n\n```\n#{$stdin.read}\n```" if $stdin.stat.pipe?
      Elelem::Terminal.new.markdown Elelem.ask(prompt, provider: @provider)
    end

    def files
      files = $stdin.stat.pipe? ? $stdin.readlines : `git ls-files`.lines
      puts "<documents>"
      files.each_with_index do |line, i|
        path = line.strip
        next if path.empty? || !File.file?(path)
        puts %Q{<document index="#{i + 1}"><source>#{path}</source><document_content><![CDATA[#{File.read(path)}]]></document_content></document>}
      end
      puts "</documents>"
    end
  end
end
