# frozen_string_literal: true

module Elelem
  class MCP
    def initialize(config_path = ".mcp.json")
      @config = File.exist?(config_path) ? JSON.parse(IO.read(config_path)) : {}
      @servers = {}
    end

    def tools
      @config.fetch("mcpServers", {}).flat_map do |name, _|
        server(name).tools.map do |tool|
          [
            "#{name}_#{tool["name"]}",
            {
              description: tool["description"],
              params: tool.dig("inputSchema", "properties") || {},
              required: tool.dig("inputSchema", "required") || [],
              fn: ->(a) { server(name).call(tool["name"], a) }
            }
          ]
        end
      end.to_h
    end

    def close
      @servers.each_value(&:close)
    end

    private

    def server(name)
      @servers[name] ||= Server.new(**@config.dig("mcpServers", name).transform_keys(&:to_sym))
    end

    class Server
      def initialize(command:, args: [], env: {})
        resolved_env = env.transform_values { |v| v.gsub(/\$\{(\w+)\}/) { ENV[$1] } }
        @stdin, @stdout, @stderr, @wait = Open3.popen3(resolved_env, command, *args)
        @id = 0
        initialize!
      end

      def tools
        request("tools/list")["tools"]
      end

      def call(name, args)
        result = request("tools/call", { name: name, arguments: args })
        { content: result["content"]&.map { |c| c["text"] }&.join("\n") }
      end

      def close
        @stdin.close rescue nil
        @stdout.close rescue nil
        @stderr.close rescue nil
        @wait.kill rescue nil
      end

      private

      def initialize!
        request("initialize", {
          protocolVersion: "2024-11-05",
          capabilities: {},
          clientInfo: { name: "elelem", version: VERSION }
        })
        notify("notifications/initialized")
      end

      def request(method, params = {})
        send_msg(id: @id += 1, method: method, params: params)
        read_response(@id)
      end

      def notify(method, params = {})
        send_msg(method: method, params: params)
      end

      def send_msg(msg)
        @stdin.puts({ jsonrpc: "2.0", **msg }.to_json)
        @stdin.flush
      end

      def read_response(id)
        loop do
          line = @stdout.gets
          raise "Server closed" unless line
          msg = JSON.parse(line)
          return msg["result"] if msg["id"] == id
          raise msg["error"]["message"] if msg["error"]
        end
      end
    end
  end
end
