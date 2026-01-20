# frozen_string_literal: true

module Elelem
  class Agent
    COMMANDS = %w[/clear /context /exit /help].freeze
    MAX_CONTEXT_MESSAGES = 50

    attr_reader :history, :client, :toolbox, :terminal

    def initialize(client, toolbox, terminal: nil, history: nil)
      @client = client
      @toolbox = toolbox
      @terminal = terminal || Terminal.new(commands: COMMANDS)
      @history = history || [{ role: "system", content: system_prompt }]
      @toolbox.add("task", task_tool)
      @mcp = MCP.new
      @mcp.tools.each { |name, tool| @toolbox.add(name, tool) }
    end

    def repl
      terminal.say "elelem v#{VERSION}"
      loop do
        input = terminal.ask("> ")
        break if input.nil?
        next if input.empty?
        input.start_with?("/") ? command(input) : turn(input)
      end
    end

    def command(input)
      case input
      when "/exit" then exit(0)
      when "/clear"
        @history = [{ role: "system", content: system_prompt }]
        terminal.say "  → context cleared"
      when "/context"
        terminal.say JSON.pretty_generate(history)
      else
        terminal.say "/clear /context /exit"
      end
    end

    def turn(input)
      history << { role: "user", content: input }
      compact_if_needed
      ctx = []
      content = nil

      loop do
        terminal.waiting
        content, tool_calls = fetch_response(ctx)
        terminal.say(terminal.markdown(content))
        break if tool_calls.empty?

        ctx << { role: "assistant", content: content, tool_calls: tool_calls }.compact
        tool_calls.each do |tool_call|
          ctx << { role: "tool", tool_call_id: tool_call[:id], content: process(tool_call).to_json }
        end
      end

      history << { role: "assistant", content: content }
    end

    private

    def compact_if_needed
      return if history.length < MAX_CONTEXT_MESSAGES
      terminal.say "  → compacting context (#{history.length} messages)"

      anchors = [history[0], history[1]]
      recent = history.last(MAX_CONTEXT_MESSAGES / 2)

      @history = anchors + recent
    end

    def summarize(ctx)
      ctx.reverse.find { |m| m[:role] == "assistant" }&.[](:content) || ""
    end

    def process(tool_call)
      name, args = tool_call[:name], tool_call[:arguments]
      terminal.say toolbox.header(name, args)
      toolbox.run(name.to_s, args).tap do |result|
        terminal.say toolbox.format_result(name, result)
      end
    end

    def task_tool
      {
        desc: "Delegate subtask to focused agent (complex searches, multi-file analysis)",
        params: { prompt: { type: "string" } },
        required: ["prompt"],
        fn: ->(a) {
          sub = Agent.new(client, toolbox, terminal: terminal, history: [
            { role: "system", content: "Research agent. Search, analyze, report. Be concise." }
          ])
          sub.turn(a["prompt"])
          { result: sub.history.last[:content] }
        }
      }
    end

    def fetch_response(ctx)
      content, tool_calls = "", []
      client.fetch(history + ctx, toolbox.to_h) do |chunk|
        terminal.print(terminal.think(chunk[:thinking])) if chunk[:thinking]

        case chunk[:type]
        when :delta then content += chunk[:content].to_s
        when :complete then content, tool_calls = chunk[:content].to_s, chunk[:tool_calls] || []
        end
      end
      [content, tool_calls]
    rescue => e
      terminal.say "\n  ✗ #{e.message}"
      [nil, []]
    end

    def system_prompt
      prompt = <<~PROMPT
        Terminal coding agent. Be concise. Verify your work.

        # Tools
        - read: file contents
        - write: create/overwrite file
        - execute: shell command

        # Editing
        Use `patch -p1` for multi-line changes: `echo "DIFF" | patch -p1`
        Use sed for single-line changes: `sed -i'' 's/old/new/' file`
        Use write for new files or full rewrites

        # Search
        Use `rg` for text search: `rg -n "pattern" .`
        Use `fd` for file discovery: `fd -e rb .`
        Use `sg` (ast-grep) for structural search: `sg -p 'def $NAME' -l ruby`

        # Task Management
        For complex tasks:
        1. State plan before acting
        2. Work through steps one at a time
        3. Summarize what was done

        # Long Tasks
        For complex multi-step work, write notes to .elelem/scratch.md

        # Policy
        - Explain before non-trivial commands
        - Verify changes (read file, run tests)
        - No interactive flags (-i, -p)

        # Environment
        pwd: #{Dir.pwd}
        platform: #{RUBY_PLATFORM.split("-").last}
        date: #{Date.today}
        #{git_branch}

        # Codebase
        #{repo_map}
      PROMPT
      prompt += "\n\n# Project Instructions\n#{agents_md}" if agents_md
      prompt
    end

    def agents_md
      Pathname.pwd.ascend.each do |dir|
        file = dir / "AGENTS.md"
        return file.read if file.exist?
      end
      nil
    end

    def git_branch
      return unless File.exist?(".git")
      "branch: #{`git branch --show-current`.strip}"
    rescue
      nil
    end

    def repo_map
      `ctags -x --sort=no --languages=Ruby,Python,JavaScript,TypeScript,Go,Rust -R . 2>/dev/null`
        .lines
        .reject { |l| l.include?("vendor/") || l.include?("node_modules/") || l.include?("spec/") }
        .first(100)
        .join
    rescue
      ""
    end
  end
end
