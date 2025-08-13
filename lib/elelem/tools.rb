# frozen_string_literal: true

module Elelem
  class Tools
    def initialize(configuration, tools)
      @configuration = configuration
      @tools = tools
    end

    def banner
      tools.map(&:banner).sort.join("\n  ")
    end

    def execute(tool_call)
      name = tool_call.dig("function", "name")
      args = tool_call.dig("function", "arguments")

      tools.find { |tool| tool.name == name }&.call(args)
    end

    def to_h
      tools.map(&:to_h)
    end

    private

    attr_reader :configuration, :tools
  end
end
