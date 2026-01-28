# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :conversation, :client, :toolbox, :terminal, :commands, :system_prompt
    attr_writer :terminal, :toolbox, :commands

    def initialize(client, toolbox: Toolbox.new, terminal: nil, system_prompt: nil, commands: nil)
      @client = client
      @toolbox = toolbox
      @commands = commands || Commands.new
      @terminal = terminal
      @conversation = Conversation.new
      @system_prompt = SystemPrompt.new(system_prompt)
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
      parts = input.delete_prefix("/").split(" ", 2)
      name, args = parts[0], parts[1]
      commands.run(name, args) || terminal.say(commands.names.join(" "))
    end

    def context
      @conversation.to_a(system_prompt: system_prompt.render)
    end

    def fork(system_prompt:)
      Agent.new(client, toolbox: toolbox, terminal: terminal, system_prompt: system_prompt.template)
    end

    def turn(input)
      @conversation.add(role: "user", content: input)
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

      @conversation.add(role: "assistant", content: content)
      content
    end

    private

    def process(tool_call)
      name, args = tool_call[:name], tool_call[:arguments]
      terminal.say toolbox.header(name, args)
      toolbox.run(name.to_s, args)
    end

    def fetch_response(ctx)
      content = String.new
      tool_calls = []

      client.fetch(@conversation.to_a(system_prompt: system_prompt.render) + ctx, toolbox.to_a) do |event|
        case event[:type]
        when "saying"
          content << event[:text].to_s
        when "thinking"
          terminal.print(terminal.think(event[:text]))
        when "tool_call"
          tool_calls << { id: event[:id], name: event[:name], arguments: event[:arguments] }
        end
      end

      [content, tool_calls]
    rescue => e
      terminal.say "\n  ✗ #{e.message}"
      ["Error: #{e.message} #{e.backtrace.join("\n")}", []]
    end
  end
end
