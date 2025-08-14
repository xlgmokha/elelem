# frozen_string_literal: true

module Elelem
  module States
    class Idle
      def run(agent)
        agent.logger.debug("Idling...")
        agent.tui.say("#{Dir.pwd} (#{agent.model}) [#{git_branch}]", colour: :magenta, newline: true)
        input = agent.tui.prompt("モ ")
        agent.quit if input.nil? || input.empty? || input == "exit" || input == "quit"

        agent.conversation.add(role: :user, content: input)
        agent.transition_to(Working)
      end

      private

      def git_branch
        `git branch --no-color --show-current --no-abbrev`.strip
      end
    end
  end
end
