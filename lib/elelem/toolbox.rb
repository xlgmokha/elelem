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
      "web_fetch" => {
        desc: "Fetch URL content",
        params: { url: { type: "string" } },
        required: ["url"],
        fn: ->(a) { r = Net::Hippie::Client.new.get(a["url"]); { status: r.code.to_i, body: r.body } }
      },
      "web_search" => {
        desc: "Search web via DuckDuckGo",
        params: { query: { type: "string" } },
        required: ["query"],
        fn: ->(a) { q = CGI.escape(a["query"]); JSON.parse(Net::Hippie::Client.new.get("https://api.duckduckgo.com/?q=#{q}&format=json&no_html=1").body) }
      },
      "eval" => {
        desc: "Execute Ruby code",
        params: { ruby: { type: "string" } },
        required: ["ruby"],
        fn: nil
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
      return { result: binding.eval(args["ruby"]) } if name == "eval"

      tool[:fn].call(args)
    rescue => e
      { error: e.message }
    end
  end
end
