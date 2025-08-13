# frozen_string_literal: true

module Elelem
  class Tools
    DEFAULT_TOOLS = [
      {
        type: "function",
        function: {
          name: "bash",
          description: "Execute a shell command.",
          parameters: {
            type: "object",
            properties: {
              command: { type: "string" },
            },
            required: ["command"]
          }
        },
        handler: lambda { |args|
          stdout, stderr, _status = Open3.capture3("/bin/sh", "-c", args["command"])
          stdout + stderr
        }
      },
    ]

    def initialize(configuration, tools = DEFAULT_TOOLS)
      @configuration = configuration
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

    def execute(tool_call)
      name = tool_call.dig("function", "name")
      args = tool_call.dig("function", "arguments")

      tool = @tools.find do |tool|
        tool.dig(:function, :name) == name
      end
      configuration.tui.say(args, newline: true)
      tool&.fetch(:handler)&.call(args).tap do |result|
        configuration.tui.say(result)
      end
    end

    def to_h
      @tools.map do |tool|
        {
          type: tool[:type],
          function: {
            name: tool.dig(:function, :name),
            description: tool.dig(:function, :description),
            parameters: tool.dig(:function, :parameters)
          }
        }
      end
    end

    private

    attr_reader :configuration
  end
end
