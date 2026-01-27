# frozen_string_literal: true

require_relative "mcp/token_storage"
require_relative "mcp/oauth"

module Elelem
  # https://modelcontextprotocol.io/specification/2025-11-25/server/tools.md
  class MCP
    CONFIG_PATHS = [
      "~/.elelem/mcp.json",
      ".elelem/mcp.json"
    ].freeze

    def initialize(configurations = CONFIG_PATHS)
      @config = load_config(configurations)
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

    def load_config(configurations)
      configurations.each_with_object({}) do |path, merged|
        file = File.expand_path(path)
        next unless File.exist?(file)

        config = JSON.parse(IO.read(file))
        servers = config.fetch("mcpServers", {})
        merged["mcpServers"] = (merged["mcpServers"] || {}).merge(servers)
      end
    end

    def server(name)
      @servers[name] ||= build_server(@config.dig("mcpServers", name))
    end

    def build_server(config)
      if config["type"] == "http"
        HttpServer.new(url: config["url"], headers: config["headers"] || {})
      else
        Server.new(**config.transform_keys(&:to_sym))
      end
    end

    module ServerInterface
      def tools
        request("tools/list")["tools"]
      end

      def call(name, args)
        result = request("tools/call", { name: name, arguments: args })
        logger.info({ tool: name, args: args, result: result }.to_json)
        content = extract_content(result)
        result["isError"] ? { error: content } : { content: content }
      end

      def extract_content(result)
        if (structured = result["structuredContent"])
          structured
        else
          result["content"]&.map { |c| c["text"] }&.join("\n")
        end
      end

      def logger
        @logger ||= Logger.new("mcp.log")
      end

      private

      def handshake!
        request("initialize", {
          protocolVersion: "2025-06-18",
          capabilities: {},
          clientInfo: { name: "elelem", version: VERSION }
        })
        notify("notifications/initialized")
      end
    end

    class Server
      include ServerInterface

      def initialize(command:, args: [], env: {})
        resolved_env = env.transform_values do |v|
          v.gsub(/\$\{(\w+)\}/) { ENV[$1] || raise("Missing environment variable: #{$1}") }
        end
        @stdin, @stdout, @stderr, @wait = Open3.popen3(resolved_env, command, *args)
        @id = 0
        handshake!
      end

      def close
        [@stdin, @stdout, @stderr].each { |io| io.close rescue nil }
        @wait.kill rescue nil
      end

      private

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

    class HttpServer
      include ServerInterface

      def initialize(url:, headers: {}, http: Elelem::Net.http)
        @url = url
        @headers = resolve_headers(headers)
        @http = http
        @id = 0
        @session_id = nil
        @access_token = nil
        handshake!
      end

      def close
      end

      private

      def resolve_headers(headers)
        headers.transform_values do |v|
          v.gsub(/\$\{(\w+)\}/) do
            ENV[$1] || raise("Missing environment variable: #{$1}")
          end
        end
      end

      def request(method, params = {})
        msg = { jsonrpc: "2.0", id: @id += 1, method: method, params: params }
        response = post(msg)
        raise response["error"]["message"] if response["error"]
        response["result"]
      end

      def notify(method, params = {})
        msg = { jsonrpc: "2.0", method: method, params: params }
        post(msg)
      end

      def post(msg, retry_auth: true)
        result = nil
        needs_auth = false
        error = nil

        @http.post(@url, headers: request_headers, body: msg) do |response|
          case response
          when ::Net::HTTPSuccess
            @session_id ||= response["Mcp-Session-Id"]
            result = parse_response(response)
          when ::Net::HTTPUnauthorized
            needs_auth = true
          else
            error = "HTTP #{response.code}: #{response.body}"
          end
        end

        raise error if error
        if needs_auth
          raise "Authorization failed" unless retry_auth

          @access_token = OAuth.new(@url, http: @http).token
          return post(msg, retry_auth: false)
        end
        result
      end

      def request_headers
        base = { "Accept" => "application/json, text/event-stream" }
        base["Mcp-Session-Id"] = @session_id if @session_id
        base["Authorization"] = "Bearer #{@access_token}" if @access_token
        @headers.merge(base)
      end

      def parse_response(response)
        if response.content_type&.include?("text/event-stream")
          parse_sse(response)
        elsif response.body && !response.body.empty?
          JSON.parse(response.body)
        end
      end

      def parse_sse(response)
        buffer = String.new
        result = nil

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n"))
            line = buffer.slice!(0, index + 1).strip
            next unless line.start_with?("data: ")

            result = JSON.parse(line.delete_prefix("data: "))
          end
        end

        result
      end
    end
  end
end
