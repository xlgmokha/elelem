# frozen_string_literal: true

module Elelem
  class FakeTerminal
    attr_reader :output, :selections

    def initialize(inputs: [], selections: {})
      @inputs = inputs
      @selections = selections
      @output = []
    end

    def ask(_prompt)
      @inputs.shift
    end

    def say(message)
      @output << message
    end

    def write(message)
      @output << message
    end

    def select(question, _options, &block)
      selected = @selections[question]
      block.call(selected) if selected
    end
  end
end
