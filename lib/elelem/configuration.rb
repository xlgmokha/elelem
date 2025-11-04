# frozen_string_literal: true

module Elelem
  class Configuration
    attr_reader :host, :model, :token

    def initialize(host:, model:, token:)
      @host = host
      @model = model
      @token = token
    end

    def tui
      @tui ||= TUI.new($stdin, $stdout)
    end

    def api
      @api ||= Api.new(self)
    end

    def logger
      @logger ||= Logger.new("#{Time.now.strftime("%Y-%m-%d")}-elelem.log").tap do |logger|
        logger.level = ENV.fetch("LOG_LEVEL", "warn")
        logger.formatter = ->(severity, datetime, progname, message) {
          timestamp = datetime.strftime("%H:%M:%S.%3N")
          "[#{timestamp}] #{severity.ljust(5)} #{message.to_s.strip}\n"
        }
      end
    end

    def conversation
      @conversation ||= Conversation.new.tap do |conversation|
        resources = mcp_clients.map do |client|
          client.resources.map do |resource|
            resource["uri"]
          end
        end.flatten
        conversation.add(role: :tool, content: resources)
      end
    end

    def tools
      @tools ||= Tools.new(self,
        [
          Toolbox::Exec.new(self),
          Toolbox::File.new(self),
          Toolbox::Web.new(self),
          Toolbox::Prompt.new(self),
          Toolbox::Memory.new(self),
        ] + mcp_tools
      )
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
          MCPClient.new(self, [value["command"]] + value["args"])
        end
      end
    end
  end
end
