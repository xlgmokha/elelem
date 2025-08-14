# frozen_string_literal: true

module Elelem
  module States
    module Working
      class << self
        def run(agent)
          done = false
          state = Waiting.new(agent)

          loop do
            agent.api.chat(agent.conversation.history) do |chunk|
              response = JSON.parse(chunk)
              message = normalize(response["message"] || {})
              done = response["done"]

              agent.logger.debug("#{state.display_name}: #{message}")
              state = state.run(message)
            end

            break if state.nil?
            break if done && agent.conversation.history.last[:role] != :tool
          end

          agent.transition_to(States::Idle.new)
        end

        def normalize(message)
          message.reject { |_key, value| value.empty? }
        end
      end
    end
  end
end
