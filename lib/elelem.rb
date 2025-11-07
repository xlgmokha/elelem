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

  READ_TOOL = Tool.build("read", "Read complete contents of a file. Requires exact file path.", { path: { type: "string" } }, ["path"]) do |args|
    full_path = Pathname.new(args["path"]).expand_path
    full_path.exist? ? { content: full_path.read } : { error: "File not found: #{path}" }
  end

  EXEC_TOOL = Tool.build("execute", "Execute shell commands directly. Commands run in a shell context. Examples: 'date', 'git status'.", { cmd: { type: "string" }, args: { type: "array", items: { type: "string" } }, env: { type: "object", additionalProperties: { type: "string" } }, cwd: { type: "string", description: "Working directory (defaults to current)" }, stdin: { type: "string" } }, ["cmd"]) do |args|
    Elelem.shell.execute(
      args["cmd"],
      args: args["args"] || [],
      env: args["env"] || {},
      cwd: args["cwd"].to_s.empty? ? Dir.pwd : args["cwd"],
      stdin: args["stdin"]
    )
  end

  GREP_TOOL = Tool.build("grep", "Search all git-tracked files using git grep. Returns file paths with matching line numbers.", { query: { type: "string" } }, ["query"]) do |args|
    Elelem.shell.execute("git", args: ["grep", "-nI", args["query"]])
  end

  LIST_TOOL = Tool.build("list", "List all git-tracked files in the repository, optionally filtered by path.", { path: { type: "string" } }) do |args|
    Elelem.shell.execute("git", args: args["path"] ? ["ls-files", "--", args["path"]] : ["ls-files"])
  end

  PATCH_TOOL = Tool.build( "patch", "Apply a unified diff patch via 'git apply'. Use for surgical edits to existing files.", { diff: { type: "string" } }, ["diff"]) do |args|
    Elelem.shell.execute("git", args: ["apply", "--index", "--whitespace=nowarn", "-p1"], stdin: args["diff"])
  end

  WRITE_TOOL = Tool.build("write", "Write complete file contents (overwrites existing files). Creates parent directories automatically.", { path: { type: "string" }, content: { type: "string" } }, ["path", "content"]) do |args|
    full_path = Pathname.new(args["path"]).expand_path
    FileUtils.mkdir_p(full_path.dirname)
    { bytes_written: full_path.write(args["content"]) }
  end

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
