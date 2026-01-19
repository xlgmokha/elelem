# frozen_string_literal: true

module Elelem
  class Toolbox
    TOOLS = {
      "read" => {
        desc: "Read file",
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
      "execute" => {
        desc: "Run shell command (supports pipes and redirections)",
        params: { command: { type: "string" } },
        required: ["command"],
        fn: ->(a) { Elelem.sh("bash", args: ["-c", a["command"]]) { |x| $stdout.print(x) } }
      }
    }.freeze

    ALIASES = { "bash" => "execute", "sh" => "execute", "exec" => "execute", "open" => "read" }.freeze

    attr_reader :tools

    def initialize(tools = TOOLS.dup)
      @tools = tools
    end

    def add(name, tool)
      @tools[name] = tool
    end

    def header(name, args)
      "\n+ #{name.to_s.then { _1.empty? ? "?" : _1 }}(#{args})"
    end

    def run(name, args)
      name = ALIASES.fetch(name, name)
      tool = tools[name]
      return { error: "unknown tool: #{name}" } unless tool

      tool[:fn].call(args)
    rescue => e
      { error: e.message }
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

    def format_result(name, result)
      return if result[:exit_status]

      text = result[:content] || result[:error] || ""
      return if text.strip.empty?

      result[:error] ? "  ! #{text.lines.first&.strip}" : text
    end
  end
end
