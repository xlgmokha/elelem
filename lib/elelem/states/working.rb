# frozen_string_literal: true

module Elelem
  module States
    module Working
      class << self
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

        def normalize(message)
          message.reject { |_key, value| value.empty? }
        end
      end
    end
  end
end
