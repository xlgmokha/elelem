# frozen_string_literal: true

module Elelem
  class Tool
    attr_reader :name, :description, :parameters

    def initialize(name, description, parameters)
      @name = name
      @description = description
      @parameters = parameters
    end

    def banner
      [name, description].join(": ")
    end

    def to_h
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: parameters
        }
      }
    end
  end

  class BashTool < Tool
    attr_reader :tui

    def initialize(tui)
      @tui = tui
      super("bash", "Execute a shell command.", {
        parameters: {
          type: "object",
          properties: {
            command: { type: "string" }
          },
          required: ["command"]
        }
      })
    end

    def call(args)
      command = args["command"]
      output_buffer = []

      Open3.popen3("/bin/sh", "-c", command) do |stdin, stdout, stderr, wait_thread|
        stdin.close
        streams = [stdout, stderr]

        until streams.empty?
          ready = IO.select(streams, nil, nil, 0.1)

          if ready
            ready[0].each do |io|
              data = io.read_nonblock(4096)
              output_buffer << data

              if io == stderr
                tui.say(data, colour: :red, newline: false)
              else
                tui.say(data, newline: false)
              end
            rescue IO::WaitReadable
              next
            rescue EOFError
              streams.delete(io)
            end
          elsif !wait_thread.alive?
            break
          end
        end

        wait_thread.value
      end

      output_buffer.join
    end
  end

  class MCPTool < Tool
    attr_reader :client, :tui

    def initialize(client, tui, tool)
      @client = client
      @tui = tui
      super(tool["name"], tool["description"], tool["inputSchema"] || {})
    end

    def call(args)
      unless client.connected?
        error_msg = "MCP connection lost"
        tui.say(error_msg, colour: :red)
        return { success: false, output: "", error: error_msg }
      end

      result = client.call(name, args)

      if result.nil? || result.empty?
        error_msg = "Tool call failed: no response from MCP server"
        tui.say(error_msg, colour: :red)
        return { success: false, output: "", error: error_msg }
      end

      if result["error"]
        error_msg = "Tool error: #{result["error"]}"
        tui.say(error_msg, colour: :red)
        return { success: false, output: "", error: error_msg }
      end

      output = result.dig("content", 0, "text") || result.to_s
      tui.say(output)
      { success: true, output: output, error: nil }
    end
  end
end
