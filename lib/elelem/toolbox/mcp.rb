# frozen_string_literal: true

module Elelem
  module Toolbox
    class MCP < ::Elelem::Tool
      attr_reader :client, :tui

      def initialize(client, tui, tool)
        @client = client
        @tui = tui
        super(tool["name"], tool["description"], tool["inputSchema"] || {})
      end

      def call(args)
        unless client.connected?
          tui.say("MCP connection lost", colour: :red)
          return ""
        end

        result = client.call(name, args)
        tui.say(JSON.pretty_generate(result), newline: true)

        if result.nil? || result.empty?
          tui.say("Tool call failed: no response from MCP server", colour: :red)
          return result
        end

        if result["error"]
          tui.say(result["error"], colour: :red)
          return result
        end

        result.dig("content", 0, "text") || result.to_s
      end
    end
  end
end
