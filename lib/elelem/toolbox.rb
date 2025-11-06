# frozen_string_literal: true

module Elelem
  class Toolbox
    attr_reader :tools

    def initialize()
      @tools = {
        read: [grep_tool, list_tool, read_tool],
        write: [patch_tool, write_tool],
        execute: [exec_tool]
      }
    end

    def tools_for(modes)
      modes.map { |mode| tools[mode].map(&:to_h) }.flatten
    end

    def run_tool(name, args)
      case name
      when "execute" then exec_tool.call(args)
      when "grep" then grep_tool.call(args)
      when "list" then list_tool.call(args)
      when "patch" then patch_tool.call(args)
      when "read" then read_tool.call(args)
      when "write" then write_tool.call(args)
      else
        { error: "Unknown tool", name: name, args: args }
      end
    rescue => error
      { error: error.message, name: name, args: args }
    end

    private

    def expand_path(path)
      Pathname.new(path).expand_path
    end

    def exec_tool
      @exec_tools ||= Tool.new(build_tool(
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
      )) do |args|
        run_exec(
          args["cmd"],
          args: args["args"] || [],
          env: args["env"] || {},
          cwd: args["cwd"].to_s.empty? ? Dir.pwd : args["cwd"],
          stdin: args["stdin"]
        )
      end
    end

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

    def grep_tool
      @grep_tool ||= Tool.new(build_tool(
        "grep",
        "Search all git-tracked files using git grep. Returns file paths with matching line numbers.",
        { query: { type: "string" } },
        ["query"]
      )) do |args|
        run_exec("git", args: ["grep", "-nI", args["query"]])
      end
    end

    def list_tool
      @list_tool ||= Tool.new(build_tool(
        "list",
        "List all git-tracked files in the repository, optionally filtered by path.",
        { path: { type: "string" } }
      )) do |args|
        run_exec("git", args: args["path"] ? ["ls-files", "--", args["path"]] : ["ls-files"])
      end
    end

    def patch_tool
      @patch_tool ||= Tool.new(build_tool(
        "patch",
        "Apply a unified diff patch via 'git apply'. Use for surgical edits to existing files.",
        { diff: { type: "string" } },
        ["diff"]
      )) do |args|
        run_exec("git", args: ["apply", "--index", "--whitespace=nowarn", "-p1"], stdin: args["diff"])
      end
    end

    def read_tool
      @read_tool ||= Tool.new(build_tool(
        "read",
        "Read complete contents of a file. Requires exact file path.",
        { path: { type: "string" } },
        ["path"]
      )) do |args|
        read_file(args["path"])
      end
    end

    def read_file(path)
      full_path = expand_path(path)
      full_path.exist? ? { content: full_path.read } : { error: "File not found: #{path}" }
    end


    def write_tool
      @write_tool ||= Tool.new(build_tool(
        "write",
        "Write complete file contents (overwrites existing files). Creates parent directories automatically.",
        { path: { type: "string" }, content: { type: "string" } },
        ["path", "content"]
      )) do |args|
        write_file(args["path"], args["content"])
      end
    end

    def write_file(path, content)
      full_path = expand_path(path)
      FileUtils.mkdir_p(full_path.dirname)
      { bytes_written: full_path.write(content) }
    end

    def build_tool(name, description, properties, required = [])
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: {
            type: "object",
            properties: properties,
            required: required
          }
        }
      }
    end
  end
end
