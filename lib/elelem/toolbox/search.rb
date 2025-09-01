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
        pattern = args["pattern"]

        # Build search command - use git grep if in git repo, otherwise regular grep
        if ::File.directory?(".git") || `git rev-parse --git-dir 2>/dev/null`.strip != ""
          # Limit results: -m 3 = max 3 matches per file, head -20 = max 20 total lines
          command = "git grep -n -m 3 '#{pattern}'"
          command += " -- #{path}" unless path == "."
          command += " | head -20"
        else
          # For regular grep, also limit results
          command = "grep -rnw '#{pattern}' #{path} | head -20"
        end

        # Delegate to exec tool for consistent logging and streaming
        exec_tool = Elelem::Toolbox::Exec.new(@configuration)
        exec_tool.call({ "command" => command })
      end
    end
  end
end
