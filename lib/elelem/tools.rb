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

      tool = tools.find { |tool| tool.name == name }
      return "Invalid function name: #{name}" if tool.nil?
      return "Invalid function arguments: #{args}" unless tool.valid?(args)

      tool.call(args)
    end

    def to_h
      tools.map(&:to_h)
    end

    private

    attr_reader :configuration, :tools
  end
end
