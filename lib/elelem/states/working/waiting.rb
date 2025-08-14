# frozen_string_literal: true

module Elelem
  module States
    module Working
      class Waiting < State
        def initialize(agent)
          super(agent, ".", :cyan)
        end

        def process(message)
          state_for(message)&.process(message)
        end

        private

        def state_for(message)
          if message["thinking"] && !message["thinking"].empty?
            Thinking.new(agent, "*", :yellow)
          elsif message["tool_calls"]&.any?
            Executing.new(agent, ">", :magenta)
          elsif message["content"] && !message["content"].empty?
            Talking.new(agent, "~", :white)
          end
        end
      end
    end
  end
end
