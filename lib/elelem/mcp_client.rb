# frozen_string_literal: true

require "json"
require "open3"

module Elelem
  class MCPClient
    attr_reader :tools

    def initialize(configuration)
      @configuration = configuration
      @stdin, @stdout, @stderr, @worker_thread = Open3.popen3(*serena_command, pgroup: true)

      # 1. Send initialize request
      init_result = send_request(
        method: "initialize",
        params: {
          protocolVersion: "2024-11-05",
          capabilities: {
            tools: {}
          },
          clientInfo: {
            name: "Elelem",
            version: Elelem::VERSION
          }
        }
      )

      # 2. Send initialized notification (required by MCP protocol)
      send_notification(method: "notifications/initialized")

      # 3. Now we can request tools
      @tools = send_request(method: "tools/list")&.dig("tools") || []
    end

    def connected?
      @worker_thread&.alive? && @stdin && !@stdin.closed?
    end

    def call_tool(name, arguments = {})
      send_request(
        method: "tools/call",
        params: {
          name: name,
          arguments: arguments
        }
      )
    end

    private

    attr_reader :stdin, :stdout, :stderr, :worker_thread
    attr_reader :configuration

    def serena_command
      [
        "uvx",
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--transport", "stdio",
        "--context", "ide-assistant",
        "--project", Dir.pwd,
      ]
    end

    def send_request(method:, params: {})
      request = {
        jsonrpc: "2.0",
        id: Time.now.to_i,
        method: method,
      }
      request[:params] = params unless params.empty?
      configuration.logger.debug(JSON.pretty_generate(request))
      @stdin.puts(JSON.generate(request))
      @stdin.flush

      response = JSON.parse(@stdout.gets.strip)
      configuration.logger.debug(JSON.pretty_generate(response))
      if response["error"]
        configuration.logger.error(response["error"]["message"])
        {}
      else
        response["result"]
      end
    end

    def send_notification(method:, params: {})
      notification = {
        jsonrpc: "2.0",
        method: method,
      }
      notification[:params] = params unless params.empty?
      configuration.logger.debug("Sending notification: #{JSON.pretty_generate(notification)}")
      @stdin.puts(JSON.generate(notification))
      @stdin.flush
    end
  end
end
