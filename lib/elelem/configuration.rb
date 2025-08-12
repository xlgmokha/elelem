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
        logger.formatter = ->(_, _, _, message) { message.strip + "\n" }
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
