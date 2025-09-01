# frozen_string_literal: true

module Elelem
  module Toolbox
    class File < Tool
      def initialize(configuration)
        super("file", "Read and write files", {
          type: :object,
          properties: {
            action: {
              type: :string,
              enum: ["read", "write"],
              description: "Action to perform: read or write"
            },
            path: {
              type: :string,
              description: "File path"
            },
            content: {
              type: :string,
              description: "Content to write (only for write action)"
            }
          },
          required: [:action, :path]
        })
      end

      def call(args)
        action = args["action"]
        path = args["path"]
        content = args["content"]

        case action
        when "read"
          read_file(path)
        when "write"
          write_file(path, content)
        else
          "Invalid action: #{action}"
        end
      end

      private

      def read_file(path)
        ::File.read(path)
      rescue => e
        "Error reading file: #{e.message}"
      end

      def write_file(path, content)
        ::File.write(path, content)
        "File written successfully"
      rescue => e
        "Error writing file: #{e.message}"
      end
    end
  end
end
