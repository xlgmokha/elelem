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
require "shellwords"
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
end
