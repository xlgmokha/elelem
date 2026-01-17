# frozen_string_literal: true

require "fileutils"
require "json"
require "net/llm"
require "open3"
require "pathname"
require "reline"

require_relative "elelem/agent"
require_relative "elelem/terminal"
require_relative "elelem/toolbox"
require_relative "elelem/version"

Reline.input = $stdin
Reline.output = $stdout

module Elelem
  class Error < StandardError; end

  def self.sh(cmd, args: [], env: {}, cwd: Dir.pwd, stdin: nil)
    stdout, stderr, status = Open3.capture3(env, cmd, *args, chdir: cwd, stdin_data: stdin)
    { "exit_status" => status.exitstatus, "stdout" => stdout, "stderr" => stderr }
  end

  def self.start(client)
    Agent.new(client, Toolbox.new).repl
  end
end
