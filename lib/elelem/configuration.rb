# frozen_string_literal: true

module Elelem
  class Configuration
    attr_reader :host, :model, :token, :tui

    def initialize(host:, model:, token:)
      @host = host
      @model = model
      @token = token
      @tui = TUI.new
    end

    def tools
      @tools ||= Tools.new([
        Toolbox::Exec.new(self),
        Toolbox::File.new(self),
        Toolbox::Web.new(self),
        Toolbox::Prompt.new(self),
        Toolbox::Memory.new(self),
      ] + mcp_tools)
    end

    def cleanup
      @mcp_clients&.each(&:shutdown)
    end

    private

    def mcp_tools
      @mcp_tools ||= mcp_clients.map do |client|
        client.tools.map do |tool|
          Toolbox::MCP.new(client, tui, tool)
        end
      end.flatten
    end

    def mcp_clients
      @mcp_clients ||= begin
        config = Pathname.pwd.join(".mcp.json")
        return [] unless config.exist?

        JSON.parse(config.read).map do |_key, value|
          MCPClient.new([value["command"]] + value["args"])
        end
      end
    end
  end
end
