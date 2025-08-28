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
          if !response.is_a?(Net::HTTPSuccess)
            configuration.logger.error(response.inspect)
            raise response.inspect
          end

          buffer = ""
          response.read_body do |chunk|
            configuration.logger.debug(chunk)
            buffer += chunk

            while (message = extract_sse_message(buffer))
              next if message.empty?

              if message == "[DONE]"
                block.call({ "done" => true })
                break
              end

              configuration.logger.debug(message)
              json = JSON.parse(message)
              block.call(normalize(json.dig("choices", 0, "delta")))
            end
          end
        end
      end
    end

    private

    def extract_sse_message(buffer)
      message_end = buffer.index("\n\n")
      return nil unless message_end

      message_data = buffer[0...message_end]
      buffer.replace(buffer[(message_end + 2)..-1] || "")

      data_lines = message_data.split("\n").filter_map do |line|
        if line.start_with?("data: ")
          line[6..-1]
        elsif line == "data:"
          ""
        end
      end

      return "" if data_lines.empty?
      data_lines.join("\n")
    end

    def normalize(message)
      message.reject { |_key, value| value.empty? }
    end

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

      URI("#{host.sub(%r{/?$}, "")}/v1/chat/completions")
    end

    def build_request(messages)
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
        temperature: 0.1,
        tools: configuration.tools.to_h
      }.tap do |payload|
        configuration.logger.debug(JSON.pretty_generate(payload))
      end
    end
  end
end
