# frozen_string_literal: true

require "date"
require "fileutils"
require "json"
require "net/llm"
require "open3"
require "pathname"
require "reline"
require "stringio"
require "tempfile"

require_relative "elelem/agent"
require_relative "elelem/mcp"
require_relative "elelem/terminal"
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

  def self.start(client)
    Agent.new(client, Toolbox.new).repl
  end
end
