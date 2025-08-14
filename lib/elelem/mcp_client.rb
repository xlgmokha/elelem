# frozen_string_literal: true

module Elelem
  class MCPClient
    attr_reader :tools

    def initialize(configuration, command = [])
      @configuration = configuration
      @stdin, @stdout, @stderr, @worker = Open3.popen3(*command, pgroup: true)

      # 1. Send initialize request
      send_request(
        method: "initialize",
        params: {
          protocolVersion: "2025-06-08",
          capabilities: {
            tools: {}
          },
          clientInfo: {
            name: "Elelem",
            version: Elelem::VERSION
          }
        }
      )

      # 2. Send initialized notification (optional for some MCP servers)
      send_notification(method: "notifications/initialized")

      # 3. Now we can request tools
      @tools = send_request(method: "tools/list")&.dig("tools") || []
    end

    def connected?
      return false unless @worker&.alive?
      return false unless @stdin && !@stdin.closed?
      return false unless @stdout && !@stdout.closed?

      begin
        Process.getpgid(@worker.pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    def call(name, arguments = {})
      send_request(
        method: "tools/call",
        params: {
          name: name,
          arguments: arguments
        }
      )
    end

    def shutdown
      return unless connected?

      configuration.logger.debug("Shutting down MCP client")

      [@stdin, @stdout, @stderr].each do |stream|
        stream&.close unless stream&.closed?
      end

      return unless @worker&.alive?

      begin
        Process.kill("TERM", @worker.pid)
        # Give it 2 seconds to terminate gracefully
        Timeout.timeout(2) { @worker.value }
      rescue Timeout::Error
        # Force kill if it doesn't respond
        Process.kill("KILL", @worker.pid) rescue nil
      rescue Errno::ESRCH
        # Process already dead
      end
    end

    private

    attr_reader :stdin, :stdout, :stderr, :worker, :configuration

    def send_request(method:, params: {})
      return {} unless connected?

      request = {
        jsonrpc: "2.0",
        id: Time.now.to_i,
        method: method
      }
      request[:params] = params unless params.empty?
      configuration.logger.debug(JSON.pretty_generate(request))

      @stdin.puts(JSON.generate(request))
      @stdin.flush

      response_line = @stdout.gets&.strip
      return {} if response_line.nil? || response_line.empty?

      response = JSON.parse(response_line)
      configuration.logger.debug(JSON.pretty_generate(response))

      if response["error"]
        configuration.logger.error(response["error"]["message"])
        { error: response["error"]["message"] }
      else
        response["result"]
      end
    end

    def send_notification(method:, params: {})
      return unless connected?

      notification = {
        jsonrpc: "2.0",
        method: method
      }
      notification[:params] = params unless params.empty?
      configuration.logger.debug("Sending notification: #{JSON.pretty_generate(notification)}")
      @stdin.puts(JSON.generate(notification))
      @stdin.flush

      response_line = @stdout.gets&.strip
      return {} if response_line.nil? || response_line.empty?

      response = JSON.parse(response_line)
      configuration.logger.debug(JSON.pretty_generate(response))
      response
    end
  end
end
