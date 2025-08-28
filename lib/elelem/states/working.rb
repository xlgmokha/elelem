# frozen_string_literal: true

module Elelem
  module States
    module Working
      class << self
        def run(agent)
          state = Waiting.new(agent)

          loop do
            done = false
            agent.api.chat(agent.conversation.history) do |message|
              if message["done"]
                done = true
                next
              end

              agent.logger.debug("#{state.display_name}: #{message}")
              state = state.run(message)
            end

            break if state.nil?
            break if agent.conversation.history.last[:role] == :assistant && agent.conversation.history.last[:content]&.strip&.end_with?("I am finished with the task.")

            # For simple responses, check if we should return to idle
            if done && agent.conversation.history.last[:role] == :assistant && 
               !agent.conversation.history.last[:content]&.strip&.end_with?("I am finished with the task.")
              # Check if this looks like a simple response (no pending tools/reasoning)
              last_message = agent.conversation.history.last[:content]&.strip
              if last_message && !last_message.empty?
                break
              end
            end
          end

          agent.transition_to(States::Idle.new)
        end
      end
    end
  end
end
