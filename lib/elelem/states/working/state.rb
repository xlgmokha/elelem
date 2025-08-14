# frozen_string_literal: true

module Elelem
  module States
    module Working
      class State
        attr_reader :agent

        def initialize(agent, icon, colour)
          @agent = agent

          agent.logger.debug("#{display_name}...")
          agent.tui.show_progress("#{display_name}...", icon, colour: colour)
        end

        def run(message)
          process(message)
        end

        def display_name
          self.class.name.split("::").last
        end
      end
    end
  end
end
