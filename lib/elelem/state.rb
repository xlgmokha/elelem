# frozen_string_literal: true

module Elelem
  class Working
    class State
      attr_reader :agent

      def initialize(agent, icon, colour)
        @agent = agent

        agent.logger.debug("#{display_name}...")
        agent.tui.show_progress("#{display_name}...", icon, colour: colour)
      end

      def display_name
        self.class.name.split("::").last
      end
    end

    class Waiting < State
      def initialize(agent)
        super(agent, ".", :cyan)
      end

      def process(message)
        state_for(message)&.process(message)
      end

      private

      def state_for(message)
        if message["thinking"] && !message["thinking"].empty?
          Thinking.new(agent, "*", :yellow)
        elsif message["tool_calls"]&.any?
          Executing.new(agent, ">", :magenta)
        elsif message["content"] && !message["content"].empty?
          Talking.new(agent, "~", :white)
        end
      end
    end

    class Thinking < State
      def process(message)
        if message["thinking"] && !message["thinking"]&.empty?
          agent.tui.say(message["thinking"], colour: :gray, newline: false)
          self
        else
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

    class Error < State
      def initialize(agent, error_message)
        super(agent, "X", :red)
        @error_message = error_message
      end

      def process(_message)
        agent.tui.say("\nTool execution failed: #{@error_message}", colour: :red)
        Waiting.new(agent)
      end
    end

    class Talking < State
      def process(message)
        if message["content"] && !message["content"]&.empty?
          agent.conversation.add(role: message["role"], content: message["content"])
          agent.tui.say(message["content"], colour: :default, newline: false)
          self
        else
          Waiting.new(agent).process(message)
        end
      end
    end

    def run(agent)
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

      agent.transition_to(States::Idle.new)
    end

    private

    def normalize(message)
      message.reject { |_key, value| value.empty? }
    end
  end
end
