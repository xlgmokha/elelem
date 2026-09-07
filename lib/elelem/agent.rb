# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :conversation, :toolbox, :input, :output, :commands
    attr_accessor :provider

    def initialize(provider, toolbox: Toolbox.new, input: NullInput.new, output: NullOutput.new, system_prompt: nil, commands: nil)
      @provider = provider
      @toolbox = toolbox
      @commands = commands || Commands.new
      @output = output
      @input = input
      @conversation = Conversation.new
      @system_prompt = SystemPrompt.new(system_prompt)
    end

    def repl
      output.say "elelem v#{VERSION}"
      loop do
        line = input.ask("> ")
        break if line.nil?
        next if line.empty?
        line.start_with?("/") ? command(line) : turn(line)
      end
    end

    def context
      @conversation.to_a(system_prompt: @system_prompt.render)
    end

    def turn(prompt)
      @conversation.add(role: "user", content: prompt)
      ctx = []
      content = nil

      loop do
        output.waiting
        content, tool_calls = fetch_response(ctx)
        output.say(content, as: :markdown)
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

    def command(line)
      parts = line.delete_prefix("/").split(" ", 2)
      name, args = parts[0], parts[1]
      commands.run(name, args) || output.say(commands.names.join(" "))
    rescue => e
      Elelem.logger.warn("agent: #{e.message}")
      output.say(e.message, as: :error)
    end

    def process(tool_call)
      name, args = tool_call[:name], tool_call[:arguments]
      output.doing(toolbox.tool_for(name).name, args)
      Elelem.logger.debug("agent: #{name}(#{args.inspect})")
      result = toolbox.run(name.to_s, args)
      Elelem.logger.debug("agent: #{name} -> #{result.inspect}")
      result
    end

    def fetch_response(ctx)
      content = String.new
      tool_calls = []

      provider.fetch(@conversation.to_a(system_prompt: @system_prompt.render) + ctx, toolbox.to_a) do |event|
        case event[:type]
        when "saying"
          content << event[:text].to_s
        when "thinking"
          output.thinking(event[:text])
        when "doing"
          tool_calls << { id: event[:id], name: event[:name], arguments: event[:arguments] }
        end
      end

      [content, tool_calls]
    rescue => e
      Elelem.logger.warn("agent: #{e.message}")
      output.say(e.message, as: :error)
      ["Error: #{e.message}", []]
    end
  end
end
