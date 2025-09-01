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

            break if state.nil? || done
          end

          agent.transition_to(States::Idle.new)
        end
      end
    end
  end
end
