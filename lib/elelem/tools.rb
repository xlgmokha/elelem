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
      name, args = parse(tool_call)

      tool = tools.find { |tool| tool.name == name }
      return "Invalid function name: #{name}" if tool.nil?
      return "Invalid function arguments: #{args}" unless tool.valid?(args)

      CLI::UI::Frame.open(name) do
        tool.call(args)
      end
    end

    def to_h
      tools.map(&:to_h)
    end

    private

    attr_reader :configuration, :tools

    def parse(tool_call)
      name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      [name, arguments.is_a?(String) ? JSON.parse(arguments) : arguments]
    end
  end
end
