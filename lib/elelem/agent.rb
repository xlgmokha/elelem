# frozen_string_literal: true

module Elelem
  class Idle
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def run(agent)
      input = agent.prompt("\n> ")
      agent.quit if input.nil? || input.empty? || input == "exit"

      configuration.conversation.add(role: "user", content: input)
    end
  end

  class Agent
    attr_reader :configuration, :conversation, :tools

    def initialize(configuration)
      @configuration = configuration
      @conversation = configuration.conversation
      @tools = configuration.tools
      @current_state = Idle.new(configuration)
    end

    def prompt(message)
      print(message)
      $stdin.gets&.chomp
    end

    def quit
      exit
    end

    def repl
      loop do
        @current_state.run(self)

        # print "\n> "
        # input = $stdin.gets&.chomp
        # break if input.nil? || input.empty? || input == "exit"

        # conversation.add(role: "user", content: input)

        done = false
        loop do
          configuration.api.chat(conversation.history, tools) do |chunk|
            response = JSON.parse(chunk)
            done = response["done"]
            message = response["message"] || {}

            if message["thinking"]
              print message["thinking"]
            elsif message["tool_calls"]&.any?
              message["tool_calls"].each do |t|
                conversation.add(role: "tool", content: tools.execute(t))
              end
              done = false
            elsif message["content"].to_s.strip
              print message["content"]
            else
              raise chunk.inspect
            end
            $stdout.flush
          end

          break if done
        end
      end
    end
  end
end
