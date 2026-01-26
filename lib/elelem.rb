# frozen_string_literal: true

require "base64"
require "date"
require "digest"
require "erb"
require "fileutils"
require "json"
require "json_schemer"
require "net/hippie"
require "open3"
require "pathname"
require "reline"
require "securerandom"
require "stringio"
require "tempfile"
require "uri"
require "webrick"

require_relative "elelem/agent"
require_relative "elelem/mcp"
require_relative "elelem/net"
require_relative "elelem/plugins"
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

  def self.start(client, toolbox: Toolbox.new)
    Plugins.setup!(toolbox)
    Agent.new(client, toolbox).repl
  end

  def self.ask(client, prompt, toolbox: Toolbox.new)
    Plugins.setup!(toolbox)
    agent = Agent.new(client, toolbox, terminal: Terminal.new(quiet: true))
    agent.turn(prompt)
    agent.history.last[:content]
  end
end
