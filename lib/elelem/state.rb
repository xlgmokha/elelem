# frozen_string_literal: true

module Elelem
  class Idle
    def run(agent)
      agent.logger.debug("Idling...")
      agent.say("#{Dir.pwd} (#{agent.model}) [#{git_branch}]", colour: :magenta, newline: true)
      input = agent.prompt("モ ")
      agent.quit if input.nil? || input.empty? || input == "exit" || input == "quit"

      agent.conversation.add(role: :user, content: input)
      agent.transition_to(Working.new)
    end

    private

    def git_branch
      `git branch --no-color --show-current --no-abbrev`.strip
    end
  end

  class Working
    class State
      attr_reader :agent

      def initialize(agent, icon, colour)
        @agent = agent

        agent.logger.debug("#{display_name}...")
        agent.show_progress("#{display_name}...", "[#{icon}]", colour: colour)
        agent.say("\n\n", newline: false)
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
          agent.say(message["thinking"], colour: :gray, newline: false)
          self
        else
          agent.say("\n\n", newline: false)
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
        agent.say("\nTool execution failed: #{@error_message}", colour: :red)
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

      agent.transition_to(Idle.new)
    end

    private

    def normalize(message)
      message.reject { |_key, value| value.empty? }
    end
  end
end
