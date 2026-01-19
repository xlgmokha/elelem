# frozen_string_literal: true

module Elelem
  class Agent
    COMMANDS = %w[/clear /context /exit /help].freeze

    attr_reader :history, :client, :toolbox, :terminal

    def initialize(client, toolbox, terminal: nil)
      @client = client
      @toolbox = toolbox
      @history = [{ role: "system", content: system_prompt }]
      @terminal = terminal || Terminal.new(commands: COMMANDS)
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

    private

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
      ctx = []

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

      history << { role: "assistant", content: summarize(ctx) }
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
        Terminal coding agent. Be concise. Act directly, Verify your work. Use markdown.

        # Editing files
        Use sed for changes: `sed -i'' 's/search/replace/' file`
        Escape special chars: / & \\ [ ] . *
        For multi-line or complex edits, use write.

        pwd: #{Dir.pwd}
      PROMPT
      prompt += "\n\n#{IO.read("AGENTS.md")}" if File.exist?("AGENTS.md")
      prompt
    end
  end
end
