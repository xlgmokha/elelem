# frozen_string_literal: true

module Elelem
  class Api
    attr_reader :configuration, :uri

    def initialize(configuration)
      @configuration = configuration
      @uri = build_uri(configuration.host)
    end

    def chat(messages, &block)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.read_timeout = 3_600
        http.open_timeout = 10

        http.request(build_request(messages)) do |response|
          if response.is_a?(Net::HTTPSuccess)
            response.read_body(&block)
          else
            configuration.logger.error(response.inspect)
          end
        end
      end
    end

    private

    def build_uri(raw_host)
      if raw_host =~ %r{^https?://}
        host = raw_host
      else
        # No scheme – decide which one to add.
        # * localhost or 127.0.0.1 → http
        # * anything else          → https
        if raw_host.start_with?('localhost', '127.0.0.1')
          scheme = 'http://'
        else
          scheme = 'https://'
        end
        host = scheme + raw_host
      end

      endpoint = "#{host.sub(%r{/?$}, '')}/api/chat"
      URI(endpoint)
    end

    def build_request(messages)
      Net::HTTP::Post.new(uri).tap do |request|
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{configuration.token}" if configuration.token && !configuration.token.empty?
        request.body = build_payload(messages).to_json
      end
    end

    def build_payload(messages)
      {
        messages: messages,
        model: configuration.model,
        stream: true,
        keep_alive: "5m",
        options: { temperature: 0.1 },
        tools: configuration.tools.to_h
      }.tap do |payload|
        configuration.logger.debug(JSON.pretty_generate(payload))
      end
    end
  end
end
