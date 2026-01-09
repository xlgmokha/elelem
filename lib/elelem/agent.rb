# frozen_string_literal: true

module Elelem
  class Agent
    PROVIDERS = %w[ollama anthropic openai vertex-ai].freeze
    ANTHROPIC_MODELS = %w[claude-sonnet-4-20250514 claude-opus-4-20250514 claude-haiku-3-5-20241022].freeze
    VERTEX_MODELS = %w[claude-sonnet-4@20250514 claude-opus-4-5@20251101].freeze
    COMMANDS = %w[/env /mode /provider /model /shell /clear /context /exit /help].freeze
    MODES = %w[auto build plan verify].freeze
    ENV_VARS = %w[ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL OLLAMA_HOST GOOGLE_CLOUD_PROJECT GOOGLE_CLOUD_REGION].freeze

    attr_reader :conversation, :client, :toolbox, :provider

    def initialize(provider, model, toolbox)
      @conversation = Conversation.new
      @provider = provider
      @toolbox = toolbox
      @client = build_client(provider, model)
    end

    def repl
      Reline.autocompletion = true
      Reline.completion_proc = ->(target, preposing) { complete(target, preposing) }
      mode = Set.new([:read])

      loop do
        input = ask?("User> ")
        break if input.nil?
        if input.start_with?("/")
          case input
          when "/mode auto"
            mode = Set[:read, :write, :execute]
            puts "  → Mode: auto (all tools enabled)"
          when "/mode build"
            mode = Set[:read, :write]
            puts "  → Mode: build (read + write)"
          when "/mode plan"
            mode = Set[:read]
            puts "  → Mode: plan (read-only)"
          when "/mode verify"
            mode = Set[:read, :execute]
            puts "  → Mode: verify (read + execute)"
          when "/mode"
            puts "  Usage: /mode [auto|build|plan|verify]"
            puts ""
            puts "  Provider: #{provider}/#{client.model}"
            puts "  Mode: #{mode.to_a.inspect}"
            puts "  Tools: #{toolbox.tools_for(mode).map { |t| t.dig(:function, :name) }}"
          when "/exit" then exit
          when "/clear"
            conversation.clear
            puts "  → Conversation cleared"
          when "/context" then puts conversation.dump(mode)
          when "/shell"
            transcript = start_shell
            conversation.add(role: :user, content: transcript) unless transcript.strip.empty?
            puts "  → Shell session captured"
          when "/provider"
            CLI::UI::Prompt.ask("Provider?") do |handler|
              PROVIDERS.each do |name|
                handler.option(name) do |selected_provider|
                  models = models_for(selected_provider)
                  if models.empty?
                    puts "  ✗ No models available for #{selected_provider}"
                  else
                    CLI::UI::Prompt.ask("Model?") do |h|
                      models.each do |model|
                        h.option(model) { |m| switch_client(selected_provider, m) }
                      end
                    end
                  end
                end
              end
            end
          when "/model"
            models = models_for(provider)
            if models.empty?
              puts "  ✗ No models available for #{provider}"
            else
              CLI::UI::Prompt.ask("Model?") do |handler|
                models.each do |model|
                  handler.option(model) { |m| switch_model(m) }
                end
              end
            end
          when "/env"
            puts "  Usage: /env VAR cmd..."
            puts ""
            ENV_VARS.each do |var|
              value = ENV[var]
              if value
                masked = value.length > 8 ? "#{value[0..3]}...#{value[-4..]}" : "****"
                puts "  #{var}=#{masked}"
              else
                puts "  #{var}=(not set)"
              end
            end
          when %r{^/env\s+(\w+)\s+(.+)$}
            var_name = $1
            command = $2
            result = Elelem.shell.execute("sh", args: ["-c", command])
            if result["exit_status"].zero?
              value = result["stdout"].lines.first&.strip
              if value && !value.empty?
                ENV[var_name] = value
                puts "  → Set #{var_name}"
              else
                puts "  ⚠ Command produced no output"
              end
            else
              puts "  ⚠ Command failed: #{result['stderr']}"
            end
          else
            puts help_banner
          end
        else
          conversation.add(role: :user, content: input)
          result = execute_turn(conversation.history_for(mode), tools: toolbox.tools_for(mode))
          conversation.add(role: result[:role], content: result[:content])
        end
      end
    end

    private

    def ask?(text)
      Reline.readline(text, true)&.strip
    end

    def complete(target, preposing)
      line = "#{preposing}#{target}"

      if line.start_with?('/') && !preposing.include?(' ')
        return COMMANDS.select { |c| c.start_with?(line) }
      end

      case preposing.strip
      when '/mode'
        MODES.select { |m| m.start_with?(target) }
      when '/provider'
        PROVIDERS.select { |p| p.start_with?(target) }
      when '/env'
        ENV_VARS.select { |v| v.start_with?(target) }
      when %r{^/env\s+\w+\s+pass\s+show\s*$}
        complete_pass_entries(target)
      when %r{^/env\s+\w+\s+pass\s*$}
        %w[show ls insert generate edit rm].select { |c| c.start_with?(target) }
      when %r{^/env\s+\w+$}
        complete_commands(target)
      else
        complete_files(target)
      end
    end

    def complete_commands(target)
      result = Elelem.shell.execute("bash", args: ["-c", "compgen -c #{target}"])
      result["stdout"].lines.map(&:strip).first(20)
    end

    def complete_files(target)
      result = Elelem.shell.execute("bash", args: ["-c", "compgen -f #{target}"])
      result["stdout"].lines.map(&:strip).first(20)
    end

    def complete_pass_entries(target)
      store = ENV.fetch("PASSWORD_STORE_DIR", File.expand_path("~/.password-store"))
      result = Elelem.shell.execute("find", args: [store, "-name", "*.gpg"])
      result["stdout"].lines.map { |l|
        l.strip.sub("#{store}/", "").sub(/\.gpg$/, "")
      }.select { |e| e.start_with?(target) }.first(20)
    end

    def strip_ansi(text)
      text.gsub(/^Script started.*?\n/, '')
          .gsub(/\nScript done.*$/, '')
          .gsub(/\e\[[0-9;]*[a-zA-Z]/, '')
          .gsub(/\e\[\?[0-9]+[hl]/, '')
          .gsub(/[\b]/, '')
          .gsub(/\r/, '')
    end

    def start_shell
      Tempfile.create do |file|
        system("script -q #{file.path}", chdir: Dir.pwd)
        strip_ansi(File.read(file.path))
      end
    end

    def help_banner
      <<~HELP
  /env VAR cmd...
  /mode auto build plan verify
  /provider
  /model
  /shell
  /clear
  /context
  /exit
  /help
      HELP
    end

    def build_client(provider_name, model = nil)
      model_opts = model ? { model: model } : {}

      case provider_name
      when "ollama"     then Net::Llm::Ollama.new(**model_opts)
      when "anthropic"  then Net::Llm::Anthropic.new(**model_opts)
      when "openai"     then Net::Llm::OpenAI.new(**model_opts)
      when "vertex-ai"  then Net::Llm::VertexAI.new(**model_opts)
      else
        raise Error, "Unknown provider: #{provider_name}"
      end
    end

    def models_for(provider_name)
      case provider_name
      when "ollama"
        client_for_models = provider_name == provider ? client : build_client(provider_name)
        client_for_models.tags["models"]&.map { |m| m["name"] } || []
      when "openai"
        client_for_models = provider_name == provider ? client : build_client(provider_name)
        client_for_models.models["data"]&.map { |m| m["id"] } || []
      when "anthropic"
        ANTHROPIC_MODELS
      when "vertex-ai"
        VERTEX_MODELS
      else
        []
      end
    rescue KeyError => e
      puts "  ⚠ Missing credentials: #{e.message}"
      []
    rescue => e
      puts "  ⚠ Could not fetch models: #{e.message}"
      []
    end

    def switch_client(new_provider, model)
      @provider = new_provider
      @client = build_client(new_provider, model)
      puts "  → Switched to #{new_provider}/#{client.model}"
    end

    def switch_model(model)
      @client = build_client(provider, model)
      puts "  → Switched to #{provider}/#{client.model}"
    end

    def format_tool_call_result(result)
      return if result.nil?
      return result["stdout"] if result["stdout"]
      return result["stderr"] if result["stderr"]
      return result[:error] if result[:error]

      ""
    end

    def format_tool_calls_for_api(tool_calls)
      tool_calls.map do |tc|
        args = openai_client? ? JSON.dump(tc[:arguments]) : tc[:arguments]
        {
          id: tc[:id],
          type: "function",
          function: { name: tc[:name], arguments: args }
        }
      end
    end

    def openai_client?
      client.is_a?(Net::Llm::OpenAI)
    end

    def execute_turn(messages, tools:)
      turn_context = []

      loop do
        content = ""
        tool_calls = []

        print "Thinking... "
        begin
          client.fetch(messages + turn_context, tools) do |chunk|
            case chunk[:type]
            when :delta
              print chunk[:thinking] if chunk[:thinking]
              content += chunk[:content] if chunk[:content]
            when :complete
              content = chunk[:content] if chunk[:content]
              tool_calls = chunk[:tool_calls] || []
            end
          end
        rescue => e
          puts "\n  ✗ API Error: #{e.message}"
          return { role: "assistant", content: "[Error: #{e.message}]" }
        end

        puts "\nAssistant> #{content}" unless content.to_s.empty?
        api_tool_calls = tool_calls.any? ? format_tool_calls_for_api(tool_calls) : nil
        turn_context << { role: "assistant", content: content, tool_calls: api_tool_calls }.compact

        if tool_calls.any?
          tool_calls.each do |call|
            name = call[:name]
            args = call[:arguments]

            puts "\nTool> #{name}(#{args})"
            result = toolbox.run_tool(name, args)
            puts format_tool_call_result(result)
            turn_context << { role: "tool", tool_call_id: call[:id], content: JSON.dump(result) }
          end

          tool_calls = []
          next
        end

        return { role: "assistant", content: content }
      end
    end
  end
end
