# frozen_string_literal: true

module Elelem
  module States
    module Working
      class << self
        def run(agent)
          state = Waiting.new(agent)

          loop do
            streaming_done = false
            finish_reason = nil

            agent.api.chat(agent.conversation.history) do |message|
              if message["done"]
                streaming_done = true
                next
              end

              if message["finish_reason"]
                finish_reason = message["finish_reason"]
                agent.logger.debug("Working: finish_reason = #{finish_reason}")
              end

              new_state = state.run(message)
              if new_state.class != state.class
                agent.logger.info("STATE: #{state.display_name} -> #{new_state.display_name}")
              end
              state = new_state
            end

            # Only exit when task is actually complete, not just streaming done
            if finish_reason == "stop"
              agent.logger.debug("Working: Task complete, exiting to Idle")
              break
            elsif finish_reason == "tool_calls"
              agent.logger.debug("Working: Tool calls finished, continuing conversation")
              # Continue loop to process tool results
            elsif streaming_done && finish_reason.nil?
              agent.logger.debug("Working: Streaming done but no finish_reason, continuing")
              # Continue for cases where finish_reason comes in separate chunk
            end
          end

          agent.transition_to(States::Idle.new)
        end
      end
    end
  end
end
