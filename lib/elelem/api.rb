# frozen_string_literal: true

module Elelem
  class Api
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def chat(messages, &block)
      body = {
        messages: messages,
        model: configuration.model,
        stream: true,
        keep_alive: "5m",
        options: { temperature: 0.1 },
        tools: configuration.tools.to_h
      }
      configuration.logger.debug(JSON.pretty_generate(body))
      json_body = body.to_json

      req = Net::HTTP::Post.new(configuration.uri)
      req["Content-Type"] = "application/json"
      req.body = json_body
      req["Authorization"] = "Bearer #{configuration.token}" if configuration.token

      configuration.http.request(req) do |response|
        raise response.inspect unless response.code == "200"

        response.read_body(&block)
      end
    end
  end
end
