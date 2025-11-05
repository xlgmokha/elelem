# frozen_string_literal: true

module Elelem
  class Tools
    def initialize(tools)
      @tools = tools
    end

    def add(name, description, parameters, &block)
      @tools << Tool.new(name, description, parameters, &block)
    end

    def execute(tool_call)
      name, args = parse(tool_call)

      tool = tools.find { |tool| tool.name == name }
      return "Invalid function name: #{name}" if tool.nil?
      return "Invalid function arguments: #{args}" unless tool.valid?(args)

      tool.call(args)
    end

    def to_h
      tools.map(&:to_h)
    end

    private

    attr_reader :tools

    def parse(tool_call)
      name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      [name, arguments.is_a?(String) ? JSON.parse(arguments) : arguments]
    end
  end
end
