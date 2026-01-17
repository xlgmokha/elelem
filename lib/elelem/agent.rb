# frozen_string_literal: true

module Elelem
  class Agent
    COMMANDS = %w[/clear /context /exit /help].freeze
    MAX_LINES = 30

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
      ctx, errors = [], 0

      loop do
        terminal.waiting
        content, tool_calls = fetch_response(ctx)
        terminal.newline
        return if content.nil?

        terminal.say(terminal.markdown(content)) unless content.empty?
        ctx << { role: "assistant", content: content, tool_calls: tool_calls.empty? ? nil : tool_calls }.compact

        break if tool_calls.empty?

        tool_calls.each do |tc|
          name, args = tc[:name], tc[:arguments]
          terminal.say "\n#{format_tool_display(name, args)}"
          result = truncate(toolbox.run(name, args))
          terminal.say format_tool_result(name, result)
          ctx << { role: "tool", tool_call_id: tc[:id], content: result.to_json }
          errors += 1 if result[:error]
        end

        break if errors >= 3
      end

      final_content = ctx.reverse.find { |m| m[:role] == "assistant" }&.[](:content) || ""
      history << { role: "assistant", content: final_content }
    end

    def fetch_response(ctx)
      content, tool_calls = "", []
      client.fetch(history + ctx, toolbox.to_h) do |chunk|
        terminal.print(terminal.dim(chunk[:thinking])) if chunk[:thinking]

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

    def format_tool_display(name, args)
      "+ #{name}(#{args})"
    end

    def format_tool_result(name, result)
      text = result["stdout"] || result["stderr"] || result[:content] || result[:error] || ""
      return nil if text.strip.empty?

      result[:error] ? "  ! #{text.lines.first&.strip}" : text
    end

    def truncate(result)
      %w[stdout stderr].each do |k|
        next unless result[k].is_a?(String) && result[k].lines.size > MAX_LINES
        result[k] = result[k].lines.first(MAX_LINES).join + "… (truncated)"
      end
      result
    end

    def system_prompt
      <<~PROMPT.strip
        Terminal agent. Be concise. Act directly, verify your work. Stay grounded - only respond to what is asked.
        pwd: #{Dir.pwd}
      PROMPT
    end
  end
end
