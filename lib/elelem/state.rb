# frozen_string_literal: true

module Elelem
  class Idle
    def run(agent)
      input = agent.prompt("\n> ")
      agent.quit if input.nil? || input.empty? || input == "exit"

      agent.configuration.conversation.add(role: "user", content: input)
      agent.transition_to(ProcessingInput.new)
    end
  end

  class ProcessingInput
    class Waiting
      attr_reader :agent

      def initialize(agent)
        @agent = agent
      end

      def process(message)
        state = self

        if message["thinking"]
          state = Thinking.new(agent)
        elsif message["tool_calls"]&.any?
          state = Executing.new(agent)
        elsif message["content"].to_s.strip
          state = Talking.new(agent)
        elsif message["done"]
          state = nil
        else
          raise message.inspect
        end

        state&.process(message)
      end
    end

    class Thinking
      attr_reader :agent

      def initialize(agent)
        @agent = agent
      end

      def process(message)
        if message["thinking"]
          agent.say(message["thinking"], colour: :gray, newline: false)
          self
        else
          agent.say("", newline: true)
          Waiting.new(agent).process(message)
        end
      end
    end

    class Executing
      attr_reader :agent

      def initialize(agent)
        @agent = agent
      end

      def process(message)
        if message["tool_calls"]&.any?
          message["tool_calls"].each do |tool_call|
            agent.configuration.conversation.add(role: "tool", content: agent.execute(tool_call))
          end
        end

        Waiting.new(agent)
      end
    end

    class Talking
      attr_reader :agent

      def initialize(agent)
        @agent = agent
      end

      def process(message)
        if message["content"]
          agent.say(message["content"], colour: :default, newline: false)
          self
        else
          agent.say("", newline: true)
          Waiting.new(agent).process(message)
        end
      end
    end

    def run(agent)
      state = Waiting.new(agent)

      loop do
        agent.configuration.api.chat(agent.configuration.conversation.history) do |chunk|
          response = JSON.parse(chunk)
          message = response["message"] || {}

          state = state.process(message)
        end

        break if state.nil?
      end

      agent.transition_to(Idle.new)
    end
  end
end
