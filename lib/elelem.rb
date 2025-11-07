# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"
require "json-schema"
require "logger"
require "net/llm"
require "open3"
require "pathname"
require "reline"
require "set"
require "thor"
require "timeout"

require_relative "elelem/agent"
require_relative "elelem/application"
require_relative "elelem/conversation"
require_relative "elelem/tool"
require_relative "elelem/toolbox"
require_relative "elelem/version"

Reline.input = $stdin
Reline.output = $stdout

module Elelem
  class Error < StandardError; end

  class Shell
    def execute(command, args: [], env: {}, cwd: Dir.pwd, stdin: nil)
      cmd = command.is_a?(Array) ? command.first : command
      cmd_args = command.is_a?(Array) ? command[1..] + args : args
      stdout, stderr, status = Open3.capture3(
        env,
        cmd,
        *cmd_args,
        chdir: cwd,
        stdin_data: stdin
      )
      {
        "exit_status" => status.exitstatus,
        "stdout" => stdout.to_s,
        "stderr" => stderr.to_s
      }
    end
  end

  class << self
    def shell
      @shell ||= Shell.new
    end
  end
end
