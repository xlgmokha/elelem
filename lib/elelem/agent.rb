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
    attr_reader :current_state

    def initialize(configuration)
      @configuration = configuration
      @conversation = configuration.conversation
      @tools = configuration.tools
      transition_to(Idle.new(configuration))
    end

    def transition_to(next_state)
      @current_state = next_state
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
        current_state.run(self)

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
