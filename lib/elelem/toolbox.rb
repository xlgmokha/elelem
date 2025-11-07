# frozen_string_literal: true

module Elelem
  class Toolbox
    READ_TOOL = Tool.build("read", "Read complete contents of a file. Requires exact file path.", { path: { type: "string" } }, ["path"]) do |args|
      path = args["path"]
      full_path = Pathname.new(path).expand_path
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

    attr_reader :tools

    def initialize
      @tools_by_name = {}
      @tools = { read: [], write: [], execute: [] }
      add_tool(EXEC_TOOL, :execute)
      add_tool(GREP_TOOL, :read)
      add_tool(LIST_TOOL, :read)
      add_tool(PATCH_TOOL, :write)
      add_tool(READ_TOOL, :read)
      add_tool(WRITE_TOOL, :write)
    end

    def add_tool(tool, mode)
      @tools[mode] << tool
      @tools_by_name[tool.name] = tool
    end

    def tools_for(modes)
      modes.map { |mode| tools[mode].map(&:to_h) }.flatten
    end

    def run_tool(name, args)
      @tools_by_name[name]&.call(args) || { error: "Unknown tool", name: name, args: args }
    rescue => error
      puts error.inspect
      { error: error.message, name: name, args: args }
    end
  end
end
