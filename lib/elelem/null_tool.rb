# frozen_string_literal: true

module Elelem
  class NullTool
    def initialize(name, available: [])
      @name = name
      @available = available
    end

    def name
      "#{@name}?"
    end

    def validate(_args)
      ["unknown tool: #{@name.inspect}. Available: #{@available.join(", ")}."]
    end
  end
end
