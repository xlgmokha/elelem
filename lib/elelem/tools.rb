# frozen_string_literal: true

module Elelem
  class Tools
    DEFAULT_TOOLS = [
      {
        type: 'function',
        function: {
          name:        'execute_command',
          description: 'Execute a shell command.',
          parameters: {
            type:       'object',
            properties: { command: { type: 'string' } },
            required:   ['command']
          }
        }
      },
      {
        type: 'function',
        function: {
          name:        'ask_user',
          description: 'Ask the user to answer a question.',
          parameters: {
            type:       'object',
            properties: { question: { type: 'string' } },
            required:   ['question']
          }
        }
      }
    ]

    def initialize(tools = DEFAULT_TOOLS)
      @tools = tools
    end

    def banner
      @tools.map do |h|
        [
          h.dig(:function, :name),
          h.dig(:function, :description)
        ].join(": ")
      end.sort.join("\n  ")
    end
  end
end
