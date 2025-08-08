# frozen_string_literal: true

module Elelem
  class Agent
    attr_reader :tools, :http, :configuration

    def initialize(configuration)
      @configuration = configuration

      @conversation = configuration.conversation
      @tools = configuration.tools
    end

    def repl
      loop do
        print "\n> "
        user = STDIN.gets&.chomp
        break if user.nil? || user.empty? || user == 'exit'
        process_input(user)
        puts("\u001b[32mDone!\u001b[0m")
      end
    end

    private

    def process_input(text)
      @conversation.add(role: 'user', content: text)

      done = false
      loop do
        debug_print("Calling API...")
        call_api(@conversation.history) do |chunk|
          debug_print(chunk)

          response = JSON.parse(chunk)
          message = response['message'] || {}
          if message['thinking']
            print("\u001b[90m#{message['thinking']}\u001b[0m")
          elsif message['tool_calls']&.any?
            message['tool_calls'].each do |t|
              @conversation.add(role: 'tool', content: @tools.execute(t))
            end
          elsif message['content'].to_s.strip
            print message['content'].to_s.strip
          else
            raise chunk.inspect
          end

          done = response['done']
        end

        break if done
      end
    end

    def call_api(messages)
      body = {
        messages:   messages,
        model:      @model,
        stream:     true,
        keep_alive: '5m',
        options:      { temperature: 0.1 },
        tools:       tools.to_h
      }
      json_body = body.to_json
      debug_print(json_body)

      req = Net::HTTP::Post.new(configuration.uri)
      req['Content-Type'] = 'application/json'
      req.body = json_body
      req['Authorization'] = "Bearer #{configuration.token}" if configuration.token

      configuration.http.request(req) do |response|
        debug_print(response.inspect)
        raise response.inspect unless response.code == "200"

        response.read_body do |chunk|
          block_given? ? yield(chunk) : debug_print(chunk)
          $stdout.flush
        end
      end
    end

    def debug_print(body = nil)
      configuration.logger.debug(body) if configuration.debug && body
    end
  end
end
