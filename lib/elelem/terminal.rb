# frozen_string_literal: true

module Elelem
  class Terminal
    def initialize(commands: [], modes: [], providers: [], env_vars: [])
      @commands = commands
      @modes = modes
      @providers = providers
      @env_vars = env_vars
      @spinner_thread = nil
      setup_completion
    end

    def ask(prompt)
      Reline.readline(prompt, true)&.strip
    end

    def say(message, markdown: false)
      stop_spinner
      if markdown
        $stdout.puts TTY::Markdown.parse(message, symbols: :ascii, mode: 16)
      else
        $stdout.puts message
      end
    end

    def write(message)
      stop_spinner
      $stdout.print message
    end

    def waiting
      @spinner_thread = Thread.new do
        frames = %w[| / - \\]
        i = 0
        loop do
          $stdout.print "\r#{frames[i % frames.length]} "
          $stdout.flush
          i += 1
          sleep 0.1
        end
      end
    end

    def select(question, options, &block)
      CLI::UI::Prompt.ask(question) do |handler|
        options.each do |option|
          handler.option(option) { |selected| block.call(selected) }
        end
      end
    end

    private

    def stop_spinner
      return unless @spinner_thread

      @spinner_thread.kill
      @spinner_thread = nil
      $stdout.print "\r  \r"
    end

    def setup_completion
      Reline.autocompletion = true
      Reline.completion_proc = ->(target, preposing) { complete(target, preposing) }
    end

    def complete(target, preposing)
      line = "#{preposing}#{target}"

      if line.start_with?('/') && !preposing.include?(' ')
        return @commands.select { |c| c.start_with?(line) }
      end

      case preposing.strip
      when '/mode'
        @modes.select { |m| m.start_with?(target) }
      when '/provider'
        @providers.select { |p| p.start_with?(target) }
      when '/env'
        @env_vars.select { |v| v.start_with?(target) }
      when %r{^/env\s+\w+\s+pass(\s+show)?\s*$}
        subcommands = %w[show ls insert generate edit rm]
        matches = subcommands.select { |c| c.start_with?(target) }
        matches.any? ? matches : complete_pass_entries(target)
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
      result = Elelem.shell.execute("find", args: ["-L", store, "-name", "*.gpg"])
      result["stdout"].lines.map { |l|
        l.strip.sub("#{store}/", "").sub(/\.gpg$/, "")
      }.select { |e| e.start_with?(target) }.first(20)
    end
  end
end
