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
      request_uri = build_uri_with(timestamp)
      Net::HTTP::Post.new(request_uri).tap do |request|
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        request["User-Agent"] = "ollama/0.11.3 (amd64 linux) Go/go1.24.6"
        build_token("POST", request_uri.path, timestamp) do |token|
          request["Authorization"] = token
        end
        request.body = build_payload(messages).to_json
      end
    end

    def build_uri_with(timestamp)
      uri.dup.tap do |request_uri|
        original_query = request_uri.query
        request_uri.query = original_query ? "#{original_query}&ts=#{timestamp}" : "ts=#{timestamp}"
      end
    end

    def build_token(method, path, timestamp)
      # if uri.host == "ollama.com"
      #   private_key_path = File.expand_path("~/.ollama/id_ed25519")
      #   raise "Ollama Ed25519 key not found at #{private_key_path}" unless File.exist?(private_key_path)

      #   challenge = "#{method},#{path}?ts=#{timestamp}"
      #   private_key = load_ed25519_key(private_key_path)
      #   signature = private_key.sign(challenge)
      #   encoded_signature = Base64.strict_encode64(signature)
      #   yield encoded_signature
      # end

      # return unless configuration.token && !configuration.token.empty?

      yield "Bearer #{configuration.token}"
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

    def load_ed25519_key(key_path)
      ssh_key = Net::SSH::KeyFactory.load_private_key(key_path)
      Ed25519::SigningKey.new(ssh_key.sign_key.seed)
    end
  end
end
