# frozen_string_literal: true

module Elelem
  class Toolbox
    READ_TOOL = Tool.build("read", "Read complete contents of a file. Requires exact file path.", { path: { type: "string" } }, ["path"]) do |args|
      path = args["path"]
      full_path = Pathname.new(path).expand_path
      full_path.exist? ? { content: full_path.read } : { error: "File not found: #{path}" }
    end

    EXEC_TOOL = Tool.build("exec", "Run shell commands. Returns stdout/stderr/exit_status.", { cmd: { type: "string" }, args: { type: "array", items: { type: "string" } }, env: { type: "object", additionalProperties: { type: "string" } }, cwd: { type: "string", description: "Working directory (defaults to current)" }, stdin: { type: "string" } }, ["cmd"]) do |args|
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

    PATCH_TOOL = Tool.build("patch", "Apply a unified diff patch via 'git apply'. Use for surgical edits to existing files.", { diff: { type: "string" } }, ["diff"]) do |args|
      Elelem.shell.execute("git", args: ["apply", "--index", "--whitespace=nowarn", "-p1"], stdin: args["diff"])
    end

    WRITE_TOOL = Tool.build("write", "Write complete file contents (overwrites existing files). Creates parent directories automatically.", { path: { type: "string" }, content: { type: "string" } }, ["path", "content"]) do |args|
      full_path = Pathname.new(args["path"]).expand_path
      FileUtils.mkdir_p(full_path.dirname)
      { bytes_written: full_path.write(args["content"]) }
    end

    FETCH_TOOL = Tool.build("fetch", "Fetch content from a URL. Returns status, headers, and body.", { url: { type: "string", description: "The URL to fetch" } }, ["url"]) do |args|
      client = Net::Hippie::Client.new
      response = client.get(args["url"])
      { status: response.code.to_i, body: response.body }
    end

    WEB_SEARCH_TOOL = Tool.build("web_search", "Search the web using DuckDuckGo. Returns raw API response.", { query: { type: "string", description: "The search query" } }, ["query"]) do |args|
      query = CGI.escape(args["query"])
      url = "https://api.duckduckgo.com/?q=#{query}&format=json&no_html=1"
      client = Net::Hippie::Client.new
      response = client.get(url)
      JSON.parse(response.body)
    end

    TOOL_ALIASES = {
      "bash" => "exec",
      "duckduckgo" => "web_search",
      "ddg" => "web_search",
      "search_engine" => "web_search",
      "execute" => "exec",
      "get" => "fetch",
      "open" => "read",
      "search" => "grep",
      "sh" => "exec",
      "web" => "fetch",
    }

    def initialize
      @tools_by_name = {}
      add_tool(eval_tool(binding))
      add_tool(EXEC_TOOL)
      add_tool(FETCH_TOOL)
      add_tool(GREP_TOOL)
      add_tool(LIST_TOOL)
      add_tool(PATCH_TOOL)
      add_tool(READ_TOOL)
      add_tool(WEB_SEARCH_TOOL)
      add_tool(WRITE_TOOL)
    end

    def add_tool(tool)
      @tools_by_name[tool.name] = tool
    end

    def register_tool(name, description, properties = {}, required = [], &block)
      add_tool(Tool.build(name, description, properties, required, &block))
    end

    def tools
      @tools_by_name.values.map(&:to_h)
    end

    def run_tool(name, args)
      resolved_name = TOOL_ALIASES.fetch(name, name)
      tool = @tools_by_name[resolved_name]
      return { error: "Unknown tool", name: name, args: args } unless tool

      tool.call(args)
    rescue => error
      { error: error.message, name: name, args: args, backtrace: error.backtrace.first(5) }
    end

    def tool_schema(name)
      @tools_by_name[name]&.to_h
    end

    private

    def eval_tool(target_binding)
      Tool.build("eval", "Evaluates Ruby code with full access to register new tools via the `register_tool(name, desc, properties, required) { |args| ... }` method.", { ruby: { type: "string" } }, ["ruby"]) do |args|
        { result: target_binding.eval(args["ruby"]) }
      end
    end
  end
end
