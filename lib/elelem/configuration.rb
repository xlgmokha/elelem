# frozen_string_literal: true

module Elelem
  class TUI
    attr_reader :stdin, :stdout

    def initialize(stdin = $stdin, stdout = $stdout)
      @stdin = stdin
      @stdout = stdout
    end

    def prompt(message)
      say(message)
      stdin.gets&.chomp
    end

    def say(message, colour: :default, newline: false)
      formatted_message = colourize(message, colour: colour)
      if newline
        stdout.puts(formatted_message)
      else
        stdout.print(formatted_message)
      end
      stdout.flush
    end

    private

    def colourize(text, colour: :default)
      case colour
      when :gray
        "\e[90m#{text}\e[0m"
      else
        text
      end
    end
  end

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
      @tui ||= TUI.new
    end

    def api
      @api ||= Api.new(self)
    end

    def logger
      @logger ||= Logger.new(debug ? $stderr : "/dev/null").tap do |logger|
        logger.formatter = ->(_, _, _, msg) { msg }
      end
    end

    def uri
      @uri ||= URI("#{scheme}://#{host}/api/chat")
    end

    def conversation
      @conversation ||= Conversation.new
    end

    def tools
      @tools ||= Tools.new
    end

    private

    def scheme
      host.match?(/\A(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?\z/) ? "http" : "https"
    end
  end
end
