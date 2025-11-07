# frozen_string_literal: true

module Elelem
  class Toolbox
    attr_reader :tools

    def initialize
      @tools_by_name = {}
      @tools = { read: [], write: [], execute: [] }

      add_tool(exec_tool, :execute)
      add_tool(grep_tool, :read)
      add_tool(list_tool, :read)
      add_tool(patch_tool, :write)
      add_tool(read_tool, :read)
      add_tool(write_tool, :write)
    end

    def add_tool(tool, mode)
      @tools[mode] << tool
      @tools_by_name[tool.to_h.dig(:function, :name)] = tool
    end

    def tools_for(modes)
      modes.map { |mode| tools[mode].map(&:to_h) }.flatten
    end

    def run_tool(name, args)
      @tools_by_name[name]&.call(args) || { error: "Unknown tool", name: name, args: args }
    rescue => error
      { error: error.message, name: name, args: args }
    end

    private

    def run_exec(command, args: [], env: {}, cwd: Dir.pwd, stdin: nil)
      cmd = command.is_a?(Array) ? command.first : command
      cmd_args = command.is_a?(Array) ? command[1..] + args : args
      stdout, stderr, status = Open3.capture3(env, cmd, *cmd_args, chdir: cwd, stdin_data: stdin)
      {
        "exit_status" => status.exitstatus,
        "stdout" => stdout.to_s,
        "stderr" => stderr.to_s
      }
    end

    def exec_tool
      @exec_tools ||= Tool.build(
        "execute",
        "Execute shell commands directly. Commands run in a shell context. Examples: 'date', 'git status'.",
        {
          cmd: { type: "string" },
          args: { type: "array", items: { type: "string" } },
          env: { type: "object", additionalProperties: { type: "string" } },
          cwd: { type: "string", description: "Working directory (defaults to current)" },
          stdin: { type: "string" }
        },
        ["cmd"]
      ) do |args|
        run_exec(
          args["cmd"],
          args: args["args"] || [],
          env: args["env"] || {},
          cwd: args["cwd"].to_s.empty? ? Dir.pwd : args["cwd"],
          stdin: args["stdin"]
        )
      end
    end

    def grep_tool
      @grep_tool ||= Tool.build(
        "grep",
        "Search all git-tracked files using git grep. Returns file paths with matching line numbers.",
        { query: { type: "string" } },
        ["query"]
      ) do |args|
        run_exec("git", args: ["grep", "-nI", args["query"]])
      end
    end

    def list_tool
      @list_tool ||= Tool.build(
        "list",
        "List all git-tracked files in the repository, optionally filtered by path.",
        { path: { type: "string" } }
      ) do |args|
        run_exec("git", args: args["path"] ? ["ls-files", "--", args["path"]] : ["ls-files"])
      end
    end

    def patch_tool
      @patch_tool ||= Tool.build(
        "patch",
        "Apply a unified diff patch via 'git apply'. Use for surgical edits to existing files.",
        { diff: { type: "string" } },
        ["diff"]
      ) do |args|
        run_exec("git", args: ["apply", "--index", "--whitespace=nowarn", "-p1"], stdin: args["diff"])
      end
    end

    def read_tool
      @read_tool ||= Tool.build(
        "read",
        "Read complete contents of a file. Requires exact file path.",
        { path: { type: "string" } },
        ["path"]
      ) do |args|
        full_path = Pathname.new(args["path"]).expand_path
        full_path.exist? ? { content: full_path.read } : { error: "File not found: #{path}" }
      end
    end

    def write_tool
      @write_tool ||= Tool.build(
        "write",
        "Write complete file contents (overwrites existing files). Creates parent directories automatically.",
        { path: { type: "string" }, content: { type: "string" } },
        ["path", "content"]
      ) do |args|
        full_path = Pathname.new(args["path"]).expand_path
        FileUtils.mkdir_p(full_path.dirname)
        { bytes_written: full_path.write(args["content"]) }
      end
    end
  end
end
