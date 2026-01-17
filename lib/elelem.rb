# frozen_string_literal: true

require "fileutils"
require "json"
require "net/llm"
require "open3"
require "pathname"
require "stringio"
require "reline"

require_relative "elelem/agent"
require_relative "elelem/terminal"
require_relative "elelem/toolbox"
require_relative "elelem/version"

module Elelem
  def self.sh(cmd, args: [], cwd: Dir.pwd)
    output = StringIO.new
    Open3.popen2e(cmd, *args, chdir: cwd) do |stdin, out, wait_thr|
      stdin.close
      out.each_line do |l|
        yield l if block_given?
        output.write(l)
      end
      { exit_status: wait_thr.value.exitstatus, content: output.string }
    end
  end

  def self.start(client)
    Agent.new(client, Toolbox.new).repl
  end
end
