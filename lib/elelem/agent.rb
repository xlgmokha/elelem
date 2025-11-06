# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :conversation, :client, :toolbox

    def initialize(client, toolbox)
      @conversation = Conversation.new
      @client = client
      @toolbox = toolbox
    end

    def repl
      mode = Set.new([:read])

      loop do
        input = ask?("User> ")
        break if input.nil?
        if input.start_with?("/")
          case input
          when "/mode auto"
            mode = Set[:read, :write, :execute]
            puts "  → Mode: auto (all tools enabled)"
          when "/mode build"
            mode = Set[:read, :write]
            puts "  → Mode: build (read + write)"
          when "/mode plan"
            mode = Set[:read]
            puts "  → Mode: plan (read-only)"
          when "/mode verify"
            mode = Set[:read, :execute]
            puts "  → Mode: verify (read + execute)"
          when "/mode"
            puts "  Mode: #{mode.to_a.inspect}"
            puts "  Tools: #{toolbox.tools_for(mode).map { |t| t.dig(:function, :name) }}"
          when "/exit" then exit
          when "/clear"
            conversation.clear
            puts "  → Conversation cleared"
          when "/context" then puts conversation.dump(mode)
          else
            puts help_banner
          end
        else
          conversation.add(role: :user, content: input)
          result = execute_turn(conversation.history_for(mode), tools: toolbox.tools_for(mode))
          conversation.add(role: result[:role], content: result[:content])
        end
      end
    end

    private

    def ask?(text)
      Reline.readline(text, true)&.strip
    end

    def help_banner
      <<~HELP
  /mode auto build plan verify
  /clear
  /context
  /exit
  /help
      HELP
    end

    def format_tool_call(name, args)
      case name
      when "execute"
        cmd = args["cmd"]
        cmd_args = args["args"] || []
        cmd_args.empty? ? cmd : "#{cmd} #{cmd_args.join(' ')}"
      when "grep" then "grep(#{args["query"]})"
      when "list" then "list(#{args["path"] || "."})"
      when "patch" then "patch(#{args["diff"]&.lines&.count || 0} lines)"
      when "read" then "read(#{args["path"]})"
      when "write" then "write(#{args["path"]})"
      else
        "#{name}(#{args.to_s[0...50]})"
      end
    end

    def execute_turn(messages, tools:)
      turn_context = []

      loop do
        content = ""
        tool_calls = []

        print "Thinking..."
        client.chat(messages + turn_context, tools) do |chunk|
          msg = chunk["message"]
          if msg
            if msg["content"] && !msg["content"].empty?
              print "\r\e[K" if content.empty?
              print msg["content"]
              content += msg["content"]
            end

            tool_calls += msg["tool_calls"] if msg["tool_calls"]
          end
        end

        puts
        turn_context << { role: "assistant", content: content, tool_calls: tool_calls }.compact

        if tool_calls.any?
          tool_calls.each do |call|
            name = call.dig("function", "name")
            args = call.dig("function", "arguments")

            puts "Tool> #{format_tool_call(name, args)}"
            result = toolbox.run_tool(name, args)
            turn_context << { role: "tool", content: JSON.dump(result) }
          end

          tool_calls = []
          next
        end

        return { role: "assistant", content: content }
      end
    end
  end
end
