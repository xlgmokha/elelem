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
        use_ssl: uri.scheme == 'https',
      }
    end

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
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        request["User-Agent"] = "ollama/0.11.3 (amd64 linux) Go/go1.24.6"
        build_token do |token|
          request["Authorization"] = token
        end
        request.body = build_payload(messages).to_json
      end
    end

    def build_token
      if uri.host == "ollama.com"
        raise "Not Implemented"

        # if File.exist?("~/.ollama/id_ed25519")
          # TODO:: return signature
          # now := strconv.FormatInt(time.Now().Unix(), 10)
          # challenge := fmt.Sprintf("%s,%s?ts=%s", method, path, now)
          # token, err := auth.Sign(ctx, []byte(challenge))
          # q := requestURL.Query()
          # q.Set("ts", now)
          # requestURL.RawQuery = q.Encode()
          #
          # request["Authorization"] = token
        # end
      end

      if configuration.token && !configuration.token.empty?
        yield "Bearer #{configuration.token}"
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
