# frozen_string_literal: true

module Elelem
  class Idle
    def run(agent)
      agent.logger.debug("Idling...")
      input = agent.prompt("\n> ")
      agent.quit if input.nil? || input.empty? || input == "exit"

      agent.conversation.add(role: :user, content: input)
      agent.transition_to(Working.new)
    end
  end

  class Working
    class State
      attr_reader :agent

      def initialize(agent)
        @agent = agent
      end

      def display_name
        self.class.name.split("::").last
      end
    end

    class Waiting < State
      def process(message)
        state = self

        if message["thinking"] && !message["thinking"].empty?
          state = Thinking.new(agent)
        elsif message["tool_calls"]&.any?
          state = Executing.new(agent)
        elsif message["content"] && !message["content"].empty?
          state = Talking.new(agent)
        else
          state = nil
        end

        state&.process(message)
      end
    end

    class Thinking < State
      def process(message)
        if message["thinking"] && !message["thinking"]&.empty?
          agent.say(message["thinking"], colour: :gray, newline: false)
          self
        else
          agent.say("", newline: true)
          Waiting.new(agent).process(message)
        end
      end
    end

    class Executing < State
      def process(message)
        if message["tool_calls"]&.any?
          message["tool_calls"].each do |tool_call|
            agent.conversation.add(role: :tool, content: agent.execute(tool_call))
          end
        end

        Waiting.new(agent)
      end
    end

    class Talking < State
      def process(message)
        if message["content"] && !message["content"]&.empty?
          agent.conversation.add(role: message["role"], content: message["content"])
          agent.say(message["content"], colour: :default, newline: false)
          self
        else
          agent.say("", newline: true)
          Waiting.new(agent).process(message)
        end
      end
    end

    def run(agent)
      agent.logger.debug("Working...")
      state = Waiting.new(agent)
      done = false

      loop do
        agent.api.chat(agent.conversation.history) do |chunk|
          response = JSON.parse(chunk)
          message = normalize(response["message"] || {})
          done = response["done"]

          agent.logger.debug("#{state.display_name}: #{message}")
          state = state.process(message)
        end

        break if state.nil?
        break if done && agent.conversation.history.last[:role] != :tool
      end

      agent.transition_to(Idle.new)
    end

    private

    def normalize(message)
      message.reject { |_key, value| value.empty? }
    end
  end
end
