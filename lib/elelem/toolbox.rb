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
        fn: ->(a) { p = Pathname.new(a["path"]).expand_path; FileUtils.mkdir_p(p.dirname); { bytes: p.write(a["content"]), path: a["path"] } }
      },
      "execute" => {
        desc: "Run shell command (supports pipes and redirections)",
        params: { command: { type: "string" } },
        required: ["command"],
        fn: ->(a) { Elelem.sh("bash", args: ["-c", a["command"]]) { |x| $stdout.print(x) } }
      }
    }.freeze

    ALIASES = { "bash" => "execute", "sh" => "execute", "exec" => "execute", "open" => "read" }.freeze

    attr_reader :tools, :hooks

    def initialize(tools = TOOLS.dup)
      @tools = tools
      @hooks = { before: Hash.new { |h, k| h[k] = [] }, after: Hash.new { |h, k| h[k] = [] } }
      setup_default_hooks
    end

    def add(name, tool)
      @tools[name] = tool
    end

    def before(tool_name, &block)
      @hooks[:before][tool_name] << block
    end

    def after(tool_name, &block)
      @hooks[:after][tool_name] << block
    end

    def header(name, args)
      "\n+ #{name.to_s.then { _1.empty? ? "?" : _1 }}(#{args})"
    end

    def run(name, args)
      name = ALIASES.fetch(name, name)
      tool = tools[name]
      return { error: "unknown tool: #{name}" } unless tool

      @hooks[:before][name].each { |h| h.call(args) }
      result = tool[:fn].call(args)
      @hooks[:after][name].each { |h| h.call(args, result) }
      result
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
      return if result[:exit_status] && !result[:verify]

      parts = []
      if result[:verify]
        result[:verify].each do |cmd, v|
          status = v[:exit_status] == 0 ? "✓" : "✗"
          parts << "  #{status} #{cmd}"
          parts << v[:content].lines.first(5).map { |l| "    #{l}" }.join if v[:exit_status] != 0
        end
      end

      text = result[:content] || result[:error] || ""
      parts << (result[:error] ? "  ! #{text.lines.first&.strip}" : text) unless text.strip.empty?
      parts.join("\n") unless parts.empty?
    end

    private

    def test_commands_for(path)
      commands = []
      commands << "ruby -c #{path}" if path&.end_with?(".rb")
      commands << %w[script/test bin/test].find { |s| File.executable?(s) }
      commands.compact
    end

    def setup_default_hooks
      after("write") do |args, result|
        next if result[:error]

        result[:verify] = {}
        test_commands_for(result[:path]).each do |cmd|
          $stdout.puts "\n  → verify: #{cmd}"
          v = Elelem.sh("bash", args: ["-c", cmd]) { |x| $stdout.print(x) }
          result[:verify][cmd] = v
          break if v[:exit_status] != 0
        end
      end
    end
  end
end
