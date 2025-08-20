# frozen_string_literal: true

module Elelem
  module Toolbox
    class Search < ::Elelem::Tool
      def initialize(configuration)
        @configuration = configuration
        super("search", "Search files in project directory", {
          type: "object",
          properties: {
            pattern: {
              type: "string",
              description: "Search pattern (grep compatible)"
            },
            path: {
              type: "string",
              description: "Directory path to search from (default: project root)"
            }
          },
          required: ["pattern"]
        })
      end

      def call(args)
        path = args["path"] || "."
        `grep -rnw '#{args["pattern"]}' #{path}`
      rescue => e
        e.message
      end
    end
  end
end
