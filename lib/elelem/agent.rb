# frozen_string_literal: true

module Elelem
  class Agent
    PROVIDERS = %w[ollama anthropic openai vertex-ai].freeze
    ANTHROPIC_MODELS = %w[claude-sonnet-4-20250514 claude-opus-4-20250514 claude-haiku-3-5-20241022].freeze
    VERTEX_MODELS = %w[claude-sonnet-4@20250514 claude-opus-4-5@20251101].freeze
    COMMANDS = %w[/env /mode /provider /model /shell /clear /context /exit /help].freeze
    MODES = %w[auto build plan verify].freeze
    ENV_VARS = %w[ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL OLLAMA_HOST GOOGLE_CLOUD_PROJECT GOOGLE_CLOUD_REGION].freeze

    attr_reader :conversation, :client, :toolbox, :provider, :terminal, :permissions

    def initialize(provider, model, toolbox, terminal: nil)
      @conversation = Conversation.new
      @provider = provider
      @toolbox = toolbox
      @client = build_client(provider, model)
      @terminal = terminal || default_terminal
      @permissions = Set.new([:read])
    end

    def repl
      loop do
        input = terminal.ask("User> ")
        break if input.nil?
        if input.start_with?("/")
          handle_slash_command(input)
        else
          conversation.add(role: :user, content: input)
          result = execute_turn(conversation.history_for(permissions))
          conversation.add(role: result[:role], content: result[:content])
        end
      end
    end

    private

    def default_terminal
      Terminal.new(
        commands: COMMANDS,
        env_vars: ENV_VARS
        modes: MODES,
        providers: PROVIDERS,
      )
    end

    def handle_slash_command(input)
      case input
      when "/mode auto"
        permissions.replace([:read, :write, :execute])
        terminal.say "  → Mode: auto (all tools enabled)"
      when "/mode build"
        permissions.replace([:read, :write])
        terminal.say "  → Mode: build (read + write)"
      when "/mode plan"
        permissions.replace([:read])
        terminal.say "  → Mode: plan (read-only)"
      when "/mode verify"
        permissions.replace([:read, :execute])
        terminal.say "  → Mode: verify (read + execute)"
      when "/mode"
        terminal.say "  Usage: /mode [auto|build|plan|verify]"
        terminal.say ""
        terminal.say "  Provider: #{provider}/#{client.model}"
        terminal.say "  Permissions: #{permissions.to_a.inspect}"
        terminal.say "  Tools: #{toolbox.tools_for(permissions).map { |t| t.dig(:function, :name) }}"
      when "/exit" then exit
      when "/clear"
        conversation.clear
        terminal.say "  → Conversation cleared"
      when "/context"
        terminal.say conversation.dump(permissions)
      when "/shell"
        transcript = start_shell
        conversation.add(role: :user, content: transcript) unless transcript.strip.empty?
        terminal.say "  → Shell session captured"
      when "/provider"
        terminal.select("Provider?", PROVIDERS) do |selected_provider|
          terminal.select("Model?", models_for(selected_provider)) do |m|
            switch_client(selected_provider, m)
          end
        end
      when "/model"
        terminal.select("Model?", models_for(provider)) do |m|
          switch_model(m)
        end
      when "/env"
        terminal.say "  Usage: /env VAR cmd..."
        terminal.say ""
        ENV_VARS.each do |var|
          value = ENV[var]
          if value
            masked = value.length > 8 ? "#{value[0..3]}...#{value[-4..]}" : "****"
            terminal.say "  #{var}=#{masked}"
          else
            terminal.say "  #{var}=(not set)"
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
            terminal.say "  → Set #{var_name}"
          else
            terminal.say "  ⚠ Command produced no output"
          end
        else
          terminal.say "  ⚠ Command failed: #{result['stderr']}"
        end
      else
        terminal.say help_banner
      end
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
      terminal.say "  ⚠ Missing credentials: #{e.message}"
      []
    rescue => e
      terminal.say "  ⚠ Could not fetch models: #{e.message}"
      []
    end

    def switch_client(new_provider, model)
      @provider = new_provider
      @client = build_client(new_provider, model)
      terminal.say "  → Switched to #{new_provider}/#{client.model}"
    end

    def switch_model(model)
      @client = build_client(provider, model)
      terminal.say "  → Switched to #{provider}/#{client.model}"
    end

    def format_tool_call_result(result)
      return if result.nil?
      return result["stdout"] if result["stdout"]
      return result["stderr"] if result["stderr"]
      return result[:error] if result[:error]

      ""
    end

    def truncate_output(text, max_lines: 30)
      return text if text.nil? || text.empty?

      lines = text.to_s.lines
      if lines.size > max_lines
        lines.first(max_lines).join + "\n... (#{lines.size - max_lines} more lines)"
      else
        text
      end
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

    def execute_turn(messages)
      tools = toolbox.tools_for(permissions)
      turn_context = []
      errors = 0

      loop do
        content = ""
        tool_calls = []

        terminal.write "Thinking... "
        begin
          client.fetch(messages + turn_context, tools) do |chunk|
            case chunk[:type]
            when :delta
              terminal.write chunk[:thinking] if chunk[:thinking]
              content += chunk[:content] if chunk[:content]
            when :complete
              content = chunk[:content] if chunk[:content]
              tool_calls = chunk[:tool_calls] || []
            end
          end
        rescue => e
          terminal.say "\n  ✗ API Error: #{e.message}"
          return { role: "assistant", content: "[Error: #{e.message}]" }
        end

        terminal.say "\nAssistant> #{content}" unless content.to_s.empty?
        api_tool_calls = tool_calls.any? ? format_tool_calls_for_api(tool_calls) : nil
        turn_context << { role: "assistant", content: content, tool_calls: api_tool_calls }.compact

        if tool_calls.any?
          tool_calls.each do |call|
            name, args = call[:name], call[:arguments]
            terminal.say "\nTool> #{name}(#{args})"
            result = toolbox.run_tool(name, args, permissions: permissions)
            terminal.say truncate_output(format_tool_call_result(result))
            turn_context << { role: "tool", tool_call_id: call[:id], content: JSON.dump(result) }
            errors += 1 if result[:error]
          end
          return { role: "assistant", content: "[Stopped: too many errors]" } if errors >= 3
          next
        end

        return { role: "assistant", content: content }
      end
    end
  end
end
