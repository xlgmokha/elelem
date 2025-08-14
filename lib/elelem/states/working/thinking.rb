# frozen_string_literal: true

module Elelem
  module States
    module Working
      class Thinking < State
        def process(message)
          if message["thinking"] && !message["thinking"]&.empty?
            agent.tui.say(message["thinking"], colour: :gray, newline: false)
            self
          else
            Waiting.new(agent).process(message)
          end
        end
      end
    end
  end
end
