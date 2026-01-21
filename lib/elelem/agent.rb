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
      @history = history || []
      @memory = nil
      register_task_tool
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
        @history = []
        @memory = nil
        terminal.say "  → context cleared"
      when "/context"
        terminal.say JSON.pretty_generate(combined_history)
      else
        terminal.say "/clear /context /exit"
      end
    end

    def turn(input)
      compact_if_needed
      history << { role: "user", content: input }
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
      content
    end

    private

    def process(tool_call)
      name, args = tool_call[:name], tool_call[:arguments]
      terminal.say toolbox.header(name, args)
      toolbox.run(name.to_s, args)
    end

    def register_task_tool
      agent = self
      @toolbox.add("task",
        description: "Delegate subtask to focused agent (complex searches, multi-file analysis)",
        params: { prompt: { type: "string" } },
        required: ["prompt"]
      ) do |a|
        sub = Agent.new(agent.client, agent.toolbox, terminal: agent.terminal, history: [
          { role: "system", content: "Research agent. Search, analyze, report. Be concise." }
        ])
        sub.turn(a["prompt"])
        { result: sub.history.last[:content] }
      end
    end

    def fetch_response(ctx)
      content = ""
      tool_calls = client.fetch(combined_history + ctx, toolbox.to_a) do |delta|
        content += delta[:content].to_s
        terminal.print(terminal.think(delta[:thinking])) if delta[:thinking]
      end
      [content, tool_calls]
    rescue => e
      terminal.say "\n  ✗ #{e.message}"
      [nil, []]
    end

    def combined_history
      [{ role: "system", content: system_prompt_with_memory }] + history
    end

    def system_prompt_with_memory
      prompt = system_prompt
      prompt += "\n\n# Earlier Context\n#{@memory}" if @memory
      prompt
    end

    def compact_if_needed
      return if history.length <= MAX_CONTEXT_MESSAGES

      terminal.say "  → compacting context"
      keep = MAX_CONTEXT_MESSAGES / 2
      old = history.first(history.length - keep)

      to_summarize = @memory ? [{ role: "memory", content: @memory }, *old] : old
      @memory = summarize(to_summarize)
      @history = history.last(keep)
    end

    def summarize(messages)
      text = messages.map { |message| { role: message[:role], content: message[:content] } }.to_json

      String.new.tap do |buffer|
        client.fetch([{ role: "user", content: "Summarize key facts:\n#{text}" }], []) do |d|
          buffer << d[:content].to_s
        end
      end
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
