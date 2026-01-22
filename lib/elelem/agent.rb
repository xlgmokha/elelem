# frozen_string_literal: true

module Elelem
  class Agent
    COMMANDS = %w[/clear /context /init /shell /exit /help].freeze
    MAX_CONTEXT_MESSAGES = 50
    INIT_PROMPT = <<~PROMPT
      AGENTS.md generator. Analyze codebase and write AGENTS.md to project root.

      # AGENTS.md Spec (https://agents.md/)
      A file providing context and instructions for AI coding agents.

      ## Recommended Sections
      - Commands: build, test, lint commands
      - Code Style: conventions, patterns
      - Architecture: key components and flow
      - Testing: how to run tests

      ## Process
      1. Read README.md if present
      2. Identify language (Gemfile, package.json, go.mod)
      3. Find test scripts (bin/test, npm test)
      4. Check linter configs
      5. Write concise AGENTS.md

      Keep it minimal. No fluff.
    PROMPT

    attr_reader :history, :client, :toolbox, :terminal

    def initialize(client, toolbox, terminal: nil, history: nil, system_prompt: nil)
      @client = client
      @toolbox = toolbox
      @terminal = terminal || Terminal.new(commands: COMMANDS)
      @history = history || []
      @system_prompt = system_prompt
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
      when "/init" then init_agents_md
      when "/shell"
        transcript = start_shell
        history << { role: "user", content: transcript } unless transcript.strip.empty?
      when "/clear"
        @history = []
        @memory = nil
        terminal.say "  → context cleared"
      when "/context"
        terminal.say JSON.pretty_generate(combined_history)
      else
        terminal.say COMMANDS.join(" ")
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
      @toolbox.add("task",
        description: "Delegate subtask to focused agent (complex searches, multi-file analysis)",
        params: { prompt: { type: "string" } },
        required: ["prompt"]
      ) do |a|
        sub = Agent.new(client, toolbox, terminal: terminal,
          system_prompt: "Research agent. Search, analyze, report. Be concise.")
        sub.turn(a["prompt"])
        { result: sub.history.last[:content] }
      end
    end

    def init_agents_md
      sub = Agent.new(client, toolbox, terminal: terminal, system_prompt: INIT_PROMPT)
      sub.turn("Generate AGENTS.md for this project")
    end

    def start_shell
      Tempfile.create do |file|
        system("script", "-q", file.path, chdir: Dir.pwd)
        strip_ansi(File.read(file.path))
      end
    end

    def strip_ansi(text)
      text.gsub(/^Script started.*?\n/, "")
          .gsub(/\nScript done.*$/, "")
          .gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
          .gsub(/\e\[\?[0-9]+[hl]/, "")
          .gsub(/[\b]/, "")
          .gsub(/\r/, "")
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
      ["Error: #{e.message} #{e.backtrace.join("\n")}", []]
    end

    def combined_history
      [{ role: "system", content: system_prompt }] + history
    end

    def system_prompt
      @system_prompt || SystemPrompt.new(memory: @memory).render
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
  end
end
