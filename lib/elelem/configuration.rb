# frozen_string_literal: true

module Elelem
  class Configuration
    attr_reader :host, :model, :token, :debug

    def initialize(host:, model:, token:, debug: false)
      @host = host
      @model = model
      @token = token
      @debug = debug
    end

    def http
      @http ||= Net::HTTP.new(uri.host, uri.port).tap do |h|
        h.read_timeout = 3_600
        h.open_timeout = 10
      end
    end

    def tui
      @tui ||= TUI.new($stdin, $stdout)
    end

    def api
      @api ||= Api.new(self)
    end

    def logger
      @logger ||= Logger.new(debug ? "elelem.log" : "/dev/null").tap do |logger|
        logger.formatter = ->(_, _, _, message) { "#{message.to_s.strip}\n" }
      end
    end

    def uri
      @uri ||= URI("#{scheme}://#{host}/api/chat")
    end

    def conversation
      @conversation ||= Conversation.new
    end

    def tools
      @tools ||= Tools.new(self, [BashTool.new(self)] + mcp_tools)
    end

    private

    def scheme
      host.match?(/\A(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?\z/) ? "http" : "https"
    end

    def mcp_tools(clients = [serena_client])
      return [] if ENV["SMALL"]

      @mcp_tools ||= clients.map { |client| client.tools.map { |tool| MCPTool.new(client, tui, tool) } }.flatten
    end

    def serena_client
      MCPClient.new(self, [
        "uvx",
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--transport", "stdio",
        "--context", "ide-assistant",
        "--project", Dir.pwd
      ])
    end
  end
end
