# frozen_string_literal: true

module Elelem
  module States
    module Working
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
    end
  end
end
