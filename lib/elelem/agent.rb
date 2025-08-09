# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :configuration, :conversation, :tools

    def initialize(configuration)
      @configuration = configuration
      @conversation = configuration.conversation
      @tools = configuration.tools
    end

    def repl
      loop do
        print "\n> "
        user = $stdin.gets&.chomp
        break if user.nil? || user.empty? || user == "exit"

        process_input(user)
        puts "\u001b[32mDone!\u001b[0m"
      end
    end

    private

    def process_input(text)
      conversation.add(role: "user", content: text)

      done = false
      loop do
        call_api(conversation.history) do |chunk|
          debug_print(chunk)

          response = JSON.parse(chunk)
          done = response["done"]
          message = response["message"] || {}

          if message["thinking"]
            print message["thinking"]
            $stdout.flush
          elsif message["tool_calls"]&.any?
            puts
            message["tool_calls"].each do |t|
              command = extract_command_from_tool_call(t)
              puts "Running: #{command}"
              tool_output = tools.execute(t)
              puts tool_output
              conversation.add(role: "tool", content: tool_output)
            end
            done = false
          elsif message["content"].to_s.strip
            print message["content"]
            $stdout.flush
          else
            raise chunk.inspect
          end
        end

        break if done
      end

      puts
    end

    def call_api(messages)
      body = {
        messages: messages,
        model: configuration.model,
        stream: true,
        keep_alive: "5m",
        options: { temperature: 0.1 },
        tools: tools.to_h
      }
      json_body = body.to_json
      debug_print(json_body)

      req = Net::HTTP::Post.new(configuration.uri)
      req["Content-Type"] = "application/json"
      req.body = json_body
      req["Authorization"] = "Bearer #{configuration.token}" if configuration.token

      configuration.http.request(req) do |response|
        raise response.inspect unless response.code == "200"

        response.read_body do |chunk|
          debug_print(chunk)
          yield(chunk) if block_given?
          $stdout.flush
        end
      end
    end

    def debug_print(body = nil)
      configuration.logger.debug(body) if configuration.debug && body
    end

    def extract_command_from_tool_call(tool_call)
      function_name = tool_call.dig("function", "name")
      args = tool_call.dig("function", "arguments")

      case function_name
      when "execute_command"
        args["command"]
      when "ask_user"
        "ask user: #{args["question"]}"
      else
        function_name
      end
    end
  end
end
