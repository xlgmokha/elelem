# frozen_string_literal: true

module Elelem
  module States
    module Working
      class Thinking < State
        def process(message)
          if message["reasoning"] && !message["reasoning"]&.empty?
            agent.tui.say(message["reasoning"], colour: :gray, newline: false)
            self
          else
            Waiting.new(agent).process(message)
          end
        end
      end
    end
  end
end
