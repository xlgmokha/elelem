# frozen_string_literal: true

module Elelem
  module Toolbox
    class File < ::Elelem::Tool
      attr_reader :tui

      def initialize(configuration)
        @tui = configuration.tui
        super("file", "Read/write files in project directory", {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["read", "write", "append"],
              description: "File operation to perform"
            },
            path: {
              type: "string",
              description: "Relative path to file from project root"
            },
            content: {
              type: "string",
              description: "Content to write/apppend (only for write/append actions)"
            }
          },
          required: ["action", "path"]
        })
      end

      def call(args)
        path = Pathname.pwd.join(args["path"])
        case args["action"]
        when "read"
          path.read
        when "write"
          path.write(args["content"])
          "File written successfully"
        when "append"
          path.open("a") { |f| f << args["content"] }
          "Content appended successfully"
        end
      rescue => e
        e.message
      end
    end
  end
end
