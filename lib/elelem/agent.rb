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
        sleep 0.1
      end
    end

    def transition_to(next_state)
      if @current_state
        logger.info("AGENT: #{@current_state.class.name.split('::').last} -> #{next_state.class.name.split('::').last}")
      else
        logger.info("AGENT: Starting in #{next_state.class.name.split('::').last}")
      end
      @current_state = next_state
    end

    def execute(tool_call)
      tool_name = tool_call.dig("function", "name")
      logger.debug("TOOL: Full call - #{tool_call}")
      result = configuration.tools.execute(tool_call)
      logger.debug("TOOL: Result (#{result.length} chars)") if result
      result
    end

    def quit
      cleanup
      exit
    end

    def cleanup
      configuration.cleanup
    end

    private

    attr_reader :configuration, :current_state
  end
end
