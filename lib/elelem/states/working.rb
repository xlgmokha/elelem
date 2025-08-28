# frozen_string_literal: true

module Elelem
  module States
    module Working
      class << self
        def run(agent)
          state = Waiting.new(agent)

          loop do
            agent.api.chat(agent.conversation.history) do |message|
              agent.logger.debug("#{state.display_name}: #{message}")
              state = state.run(message)
            end

            break if state.nil?
            break if agent.conversation.history.last[:role] == :assistant && agent.conversation.history.last[:content]&.strip&.end_with?("I am finished with the task.")
          end

          agent.transition_to(States::Idle.new)
        end
      end
    end
  end
end
