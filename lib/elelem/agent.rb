# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :api, :conversation, :logger, :model, :tui

    def initialize(configuration)
      @api = configuration.api
      @tui = configuration.tui
      @configuration = configuration
      @model = configuration.model
      @conversation = configuration.conversation
      @logger = configuration.logger

      at_exit { cleanup }

      transition_to(States::Idle.new)
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

    def execute(tool_call)
      logger.debug("Execute: #{tool_call}")
      configuration.tools.execute(tool_call)
    end

    def quit
      logger.debug("Exiting...")
      cleanup
      exit
    end

    def cleanup
      logger.debug("Cleaning up agent...")
      configuration.cleanup
    end

    private

    attr_reader :configuration, :current_state
  end
end
