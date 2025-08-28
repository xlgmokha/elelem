# frozen_string_literal: true

module Elelem
  class Api
    attr_reader :configuration, :uri

    def initialize(configuration)
      @configuration = configuration
      @uri = build_uri(configuration.host)
    end

    def chat(messages, &block)
      Net::HTTP.start(uri.hostname, uri.port, http_options) do |http|
        http.request(build_request(messages)) do |response|
          if response.is_a?(Net::HTTPSuccess)
            response.read_body(&block)
          else
            configuration.logger.error(response.inspect)
            raise response.inspect
          end
        end
      end
    end

    private

    def http_options
      {
        open_timeout: 10,
        read_timeout: 3_600,
        use_ssl: uri.scheme == "https"
      }
    end

    def build_uri(raw_host)
      if raw_host =~ %r{^https?://}
        host = raw_host
      else
        # No scheme – decide which one to add.
        # * localhost or 127.0.0.1 → http
        # * anything else          → https
        scheme = raw_host.start_with?("localhost", "127.0.0.1") ? "http://" : "https://"
        host = scheme + raw_host
      end

      URI("#{host.sub(%r{/?$}, "")}/api/chat")
    end

    def build_request(messages)
      timestamp = Time.now.to_i
      Net::HTTP::Post.new(uri).tap do |request|
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{configuration.token}" if configuration.token
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
