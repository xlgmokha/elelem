# frozen_string_literal: true

require_relative "elelem/version"
require_relative "elelem/elelem"

module Elelem
  class Error < StandardError; end

  def env(k, d = nil)
    ENV.fetch(k, d)
  end

  class Agent
    attr_reader :tools, :http

    def initialize
      @host   = env('OLLAMA_HOST', 'localhost:11434')
      @model  = env('OLLAMA_MODEL', 'gpt-oss')
      @token  = env('OLLAMA_API_KEY', nil)
      @debug  = env('DEBUG', '0') == '1'
      @logger = Logger.new(@debug ? $stderr : "/dev/null")
      @logger.formatter = ->(_, _, _, msg) { msg }

      @uri = URI("#{protocol(@host)}://#{@host}/api/chat")
      @http = Net::HTTP.new(@uri.host, @uri.port).tap do |h|
        h.read_timeout = 3_600
        h.open_timeout = 10
      end

      @conversation = [{ role: 'system', content: system_message }]

      @tools = [
        {
          type: 'function',
          function: {
            name:        'execute_command',
            description: 'Execute a shell command.',
            parameters: {
              type:       'object',
              properties: { command: { type: 'string' } },
              required:   ['command']
            }
          }
        },
        {
          type: 'function',
          function: {
            name:        'ask_user',
            description: 'Ask the user to answer a question.',
            parameters: {
              type:       'object',
              properties: { question: { type: 'string' } },
              required:   ['question']
            }
          }
        }
      ]
    end

    def protocol(host)
      host.match?(/\A(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?\z/) ? 'http' : 'https'
    end

    def system_message
      <<~SYS
        You are ChatGPT, a helpful assistant with reasoning capabilities.
        Current date: #{Time.now.strftime('%Y-%m-%d')}.
        System info: `uname -a` output:
        #{`uname -a`.strip}
        Reasoning: high
      SYS
    end

    def repl
      puts "Ollama Agent (#{@model})"
      puts "  tools:\n  #{tools.map { |h| [h.dig(:function, :name), h.dig(:function, :description)].sort.join(": ") }.join("\n  ")}"

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
      @conversation << { role: 'user', content: text }

      # ::TODO state machine
      done = false
      loop do
        call_api(@conversation) do |chunk|
          debug_print(chunk)

          response = JSON.parse(chunk)
          message = response['message'] || {}
          if message['thinking']
            print("\u001b[90m#{message['thinking']}\u001b[0m")
          elsif message['tool_calls']&.any?
            message['tool_calls'].each do |t|
              result = execute_tool(t.dig('function', 'name'), t.dig('function', 'arguments'))
              puts result
              @conversation << { role: 'tool', content: result }
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
        tools:       tools
      }
      json_body = body.to_json
      debug_print(json_body)

      req = Net::HTTP::Post.new(@uri)
      req['Content-Type'] = 'application/json'
      req.body = json_body
      req['Authorization'] = "Bearer #{@token}" if @token

      http.request(req) do |response|
        response.read_body do |chunk|
          block_given? ? yield(chunk) : debug_print(chunk)
          $stdout.flush
        end
      end
    end

    def execute_tool(name, args)
      case name
      when 'execute_command'
        result = run_cmd(args['command'])
        debug_print(result) unless result[:ok]
        result[:output]
      when 'ask_user'
        puts("\u001b[35m#{args['question']}\u001b[0m")
        print "> "
        "User: #{STDIN.gets&.chomp}"
      end
    end

    def run_cmd(command)
      stdout, stderr, status = Open3.capture3('/bin/sh', '-c', command)
      { output: stdout + stderr, ok: status.success? }
    end

    def debug_print(body = nil)
      @logger.debug(body) if @debug && body
    end
  end
end
