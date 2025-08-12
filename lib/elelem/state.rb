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
      agent.transition_to(ProcessingInput.new(configuration))
    end
  end

  class ProcessingInput
    attr_reader :configuration, :conversation, :tools

    def initialize(configuration)
      @configuration = configuration
      @conversation = configuration.conversation
      @tools = configuration.tools
    end

    def run(agent)
      done = false

      loop do
        configuration.api.chat(conversation.history, tools) do |chunk|
          response = JSON.parse(chunk)
          done = response["done"]
          message = response["message"] || {}

          if message["thinking"]
            agent.say(message["thinking"], colour: :gray, newline: false)
          elsif message["tool_calls"]&.any?
            message["tool_calls"].each do |t|
              conversation.add(role: "tool", content: tools.execute(t))
            end
            done = false
          elsif message["content"].to_s.strip
            agent.say(message["content"], colour: :default, newline: false)
          else
            raise chunk.inspect
          end
        end

        break if done
      end

      agent.transition_to(Idle.new(configuration))
    end
  end
end
