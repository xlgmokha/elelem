# frozen_string_literal: true

require "elelem"
require "io/console"
require "optparse"
require "reline"

module Elelem
  class CLI
    COMMANDS = %w[chat ask files help].freeze

    def initialize(args, provider: "stub")
      @provider = provider
      @args = parse(args)
    end

    def run
      command = @args.shift || "chat"
      abort "Unknown command: #{command}" unless COMMANDS.include?(command)
      send(command)
    end

    private

    def parse(args)
      @parser = OptionParser.new do |o|
        o.banner = "Usage: #{File.basename($PROGRAM_NAME)} [command] [options] [args]"
        o.separator "\nCommands:"
        o.separator "  chat              Interactive REPL (default)"
        o.separator "  ask <prompt>      One-shot query (reads stdin if piped)"
        o.separator "  files             Output files as XML (no options)"
        o.separator "  help              Show this help"
        o.separator "\nOptions:"
        o.on("-p", "--provider NAME", "Provider to use (default: #{@provider})") { |p| @provider = p }
        o.on("-h", "--help", "Show this help") { puts o; exit }
      end
      @parser.parse!(args)
    end

    def help
      puts @parser
    end

    def chat
      Elelem.start(provider: @provider)
    rescue => e
      Elelem.logger.warn("cli: #{e.message}\n#{e.backtrace.join("\n")}")
      abort "elelem: #{e.message}"
    end

    def ask
      abort "Usage: elelem-chat ask <prompt>" if @args.empty?
      prompt = @args.join(" ")
      prompt = "#{prompt}\n\n```\n#{$stdin.read}\n```" if $stdin.stat.pipe?
      piped = !$stdout.tty?
      output = Elelem::Output.new(stream: piped ? $stderr : $stdout)
      reply = Elelem.ask(prompt, provider: @provider, output: output)
      abort "elelem: no reply" if reply.to_s.strip.empty?
      Elelem::Output.new.say(reply, as: :markdown) if piped
    rescue => e
      Elelem.logger.warn("cli: #{e.message}\n#{e.backtrace.join("\n")}")
      abort "elelem: #{e.message}"
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
