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
      @logger ||= Logger.new(debug ? "#{Time.now.strftime("%Y-%m-%d")}-elelem.log" : "/dev/null").tap do |logger|
        logger.formatter = ->(_, _, _, message) { "#{message.to_s.strip}\n" }
      end
    end

    def uri
      @uri ||= URI("#{scheme}://#{host}/api/chat")
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
      @tools ||= Tools.new(self, [Toolbox::Bash.new(self)] + mcp_tools)
    end

    def cleanup
      @mcp_clients&.each(&:shutdown)
    end

    private

    def scheme
      host.match?(/\A(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?\z/) ? "http" : "https"
    end

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
