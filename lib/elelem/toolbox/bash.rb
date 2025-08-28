# frozen_string_literal: true

module Elelem
  module Toolbox
    class Bash < ::Elelem::Tool
      attr_reader :tui

      def initialize(configuration)
        @tui = configuration.tui
        super("bash", "Run commands in /bin/bash -c. Full access to filesystem, network, processes, and all Unix tools.", {
          type: "object",
          properties: {
            command: { type: "string" }
          },
          required: ["command"]
        })
      end

      def call(args)
        command = args["command"]
        output_buffer = []

        tui.say(command, newline: true)
        Open3.popen3("/bin/bash", "-c", command) do |stdin, stdout, stderr, wait_thread|
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
  end
end
