# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :api, :conversation, :logger, :model

    def initialize(configuration)
      @api = configuration.api
      @configuration = configuration
      @model = configuration.model
      @conversation = configuration.conversation
      @logger = configuration.logger
      transition_to(Idle.new)
    end

    def repl
      loop do
        current_state.run(self)
      end
    end

    def transition_to(next_state)
      logger.debug("Transition to: #{next_state.class.name}")
      @current_state = next_state
    end

    def prompt(message)
      configuration.tui.prompt(message)
    end

    def say(message, colour: :default, newline: false)
      configuration.tui.say(message, colour: colour, newline: newline)
    end

    def execute(tool_call)
      logger.debug("Execute: #{tool_call}")
      configuration.tools.execute(tool_call)
    end

    def show_progress(message, prefix = "[.]", colour: :gray)
      configuration.tui.show_progress(message, prefix, colour: colour)
    end

    def clear_line
      configuration.tui.clear_line
    end

    def complete_progress(message = "Completed")
      configuration.tui.complete_progress(message)
    end

    def quit
      logger.debug("Exiting...")
      exit
    end

    private

    attr_reader :configuration, :current_state
  end
end
