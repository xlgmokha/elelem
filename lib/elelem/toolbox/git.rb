# frozen_string_literal: true

module Elelem
  module Toolbox
    class Git < ::Elelem::Tool
      def initialize(configuration)
        @configuration = configuration
        super("git", "Perform git operations on repository", {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["commit", "diff", "log"],
              description: "Git operation to perform"
            },
            message: {
              type: "string",
              description: "Commit message (required for commit action)"
            }
          },
          required: ["action"]
        })
      end

      def call(args)
        case args["action"]
        when "commit"
          `git add . && git commit -m "#{args["message"]}"`
          "Committed changes: #{args["message"]}"
        when "diff"
          `git diff HEAD`
        when "log"
          `git log --oneline -n 10`
        end
      rescue => e
        e.message
      end
    end
  end
end
