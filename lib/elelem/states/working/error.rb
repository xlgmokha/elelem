# frozen_string_literal: true

module Elelem
  module States
    module Working
      class Error < State
        def initialize(agent, error_message)
          super(agent, "X", :red)
          @error_message = error_message
        end

        def process(_message)
          agent.tui.say("\nTool execution failed: #{@error_message}", colour: :red)
          Waiting.new(agent)
        end
      end
    end
  end
end
