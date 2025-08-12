# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :configuration, :current_state

    def initialize(configuration)
      @configuration = configuration
      transition_to(Idle.new(configuration))
    end

    def transition_to(next_state)
      @current_state = next_state
    end

    def prompt(message)
      configuration.tui.prompt(message)
    end

    def say(message, colour: :default, newline: false)
      configuration.tui.say(message, colour: colour, newline: newline)
    end

    def quit
      exit
    end

    def repl
      loop do
        current_state.run(self)
      end
    end
  end
end
