# frozen_string_literal: true

module Elelem
  module Toolbox
    class Prompt < Tool
      def initialize
        super(
          name: "prompt",
          description: "Ask the user a question and get their response.",
          parameters: {
            type: :object,
            properties: {
              question: {
                type: :string,
                description: "The question to ask the user."
              }
            },
            required: [:question]
          }
        )
      end

      def call(agent, **args)
        agent.tui.prompt(args[:question])
      end
    end
  end
end
