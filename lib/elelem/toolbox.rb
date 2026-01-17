# frozen_string_literal: true

module Elelem
  class Toolbox
    TOOLS = {
      "read" => {
        desc: "Read file contents",
        params: { path: { type: "string" } },
        required: ["path"],
        fn: ->(a) { p = Pathname.new(a["path"]).expand_path; p.exist? ? { content: p.read } : { error: "not found" } }
      },
      "write" => {
        desc: "Write file",
        params: { path: { type: "string" }, content: { type: "string" } },
        required: ["path", "content"],
        fn: ->(a) { p = Pathname.new(a["path"]).expand_path; FileUtils.mkdir_p(p.dirname); { bytes: p.write(a["content"]) } }
      },
      "exec" => {
        desc: "Run shell command",
        params: { cmd: { type: "string" }, args: { type: "array", items: { type: "string" } }, stdin: { type: "string" } },
        required: ["cmd"],
        fn: ->(a) { Elelem.sh(a["cmd"], args: a["args"] || [], stdin: a["stdin"]) }
      },
      "grep" => {
        desc: "Search git-tracked files",
        params: { query: { type: "string" } },
        required: ["query"],
        fn: ->(a) { Elelem.sh("git", args: ["grep", "-nI", a["query"]]) }
      },
      "list" => {
        desc: "List git-tracked files",
        params: { path: { type: "string" } },
        required: [],
        fn: ->(a) { Elelem.sh("git", args: a["path"] ? ["ls-files", "--", a["path"]] : ["ls-files"]) }
      }
    }.freeze

    ALIASES = { "bash" => "exec", "sh" => "exec", "open" => "read" }.freeze

    attr_reader :tools

    def initialize(tools = TOOLS.dup)
      @tools = tools
    end

    def to_h
      tools.map do |name, t|
        {
          type: "function",
          function: {
            name: name,
            description: t[:desc],
            parameters: {
              type: "object",
              properties: t[:params],
              required: t[:required]
            }
          }
        }
      end
    end

    def run(name, args)
      name = ALIASES.fetch(name, name)
      tool = tools[name]
      return { error: "unknown tool: #{name}" } unless tool

      tool[:fn].call(args)
    rescue => e
      { error: e.message }
    end
  end
end
