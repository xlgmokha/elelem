# frozen_string_literal: true

module Elelem
  module States
    module Working
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
    end
  end
end
