# frozen_string_literal: true

module Elelem
  module Toolbox
    class Prompt < Tool
      def initialize(configuration)
        @configuration = configuration
        super("prompt", "Ask the user a question and get their response.", {
          type: :object,
          properties: {
            question: {
              type: :string,
              description: "The question to ask the user."
            }
          },
          required: [:question]
        })
      end

      def call(args)
        @configuration.tui.prompt(args["question"])
      end
    end
  end
end
