# frozen_string_literal: true

require "base64"
require "date"
require "digest"
require "erb"
require "fileutils"
require "json"
require "json_schemer"
require "logger"
require "net/hippie"
require "open3"
require "optparse"
require "pathname"
require "reline"
require "securerandom"
require "stringio"
require "tempfile"
require "uri"
require "webrick"

require_relative "elelem/agent"
require_relative "elelem/commands"
require_relative "elelem/conversation"
require_relative "elelem/mcp"
require_relative "elelem/net"
require_relative "elelem/permissions"
require_relative "elelem/plugins"
require_relative "elelem/providers"
require_relative "elelem/system_prompt"
require_relative "elelem/terminal"
require_relative "elelem/tool"
require_relative "elelem/toolbox"
require_relative "elelem/version"

module Elelem
  def self.sh(cmd, args: [], cwd: Dir.pwd, env: {})
    output = StringIO.new

    Open3.popen2e(env, cmd, *args, chdir: cwd) do |stdin, out, wait_thr|
      stdin.close
      out.each_line do |line|
        yield line if block_given?
        output.write(line)
      end

      { exit_status: wait_thr.value.exitstatus, content: output.string }
    end
  end

  def self.start(provider: "ollama", toolbox: Toolbox.new)
    client = Providers.build(provider)
    agent = Agent.new(client, toolbox: toolbox)
    Plugins.setup!(agent)
    agent.terminal = Terminal.new(commands: agent.commands)
    agent.repl
  end

  def self.ask(prompt, provider: "ollama", toolbox: Toolbox.new)
    client = Providers.build(provider)
    agent = Agent.new(client, toolbox: toolbox, terminal: Terminal.new(quiet: true))
    Plugins.setup!(agent)
    agent.turn(prompt)
    agent.conversation.last[:content]
  end

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
