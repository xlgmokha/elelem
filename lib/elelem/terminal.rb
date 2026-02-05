# frozen_string_literal: true

module Elelem
  class Terminal
    def initialize(commands: [], quiet: false)
      @commands = commands
      @quiet = quiet
      @dots_thread = nil
      @at_line_start = true
      setup_completion unless quiet?
    end

    def quiet?
      @quiet
    end

    def ask(prompt)
      Reline.readline(prompt, true)&.strip
    end

    def think(text)
      return if blank?(text)

      "\e[2;3m#{text}\e[0m"
    end

    def markdown(text)
      return if quiet? || blank?(text)

      gap
      width = $stdout.winsize[1] rescue 80
      IO.popen(["glow", "-s", "dark", "-w", width.to_s, "-"], "r+") do |io|
        io.write(text)
        io.close_write
        io.read
      end
    rescue Errno::ENOENT
      text
    end

    def print(text)
      return if quiet? || blank?(text)

      stop_dots
      $stdout.print text
      @at_line_start = false
    end

    def say(text)
      return if quiet? || blank?(text)

      stop_dots
      $stdout.puts text
      @at_line_start = true
    end

    def newline(n: 1)
      n.times { $stdout.puts("") } unless quiet?
      @at_line_start = true
    end

    def gap
      stop_dots
      newline unless @at_line_start
    end

    def display_file(path, fallback: nil)
      return if quiet?

      system("bat", "--paging=never", path) || say(fallback || path)
    end

    def waiting
      return if quiet?

      @dots_thread = Thread.new do
        loop do
          $stdout.print "."
          $stdout.flush
          sleep 0.1
        end
      end
    end

    private

    def blank?(text)
      text.nil? || text.to_s.strip.empty?
    end

    def stop_dots
      return unless @dots_thread

      @dots_thread.kill
      @dots_thread = nil
      newline
    end

    def setup_completion
      Reline.autocompletion = true
      Reline.completion_proc = ->(target, preposing) { complete(target, preposing) }
    end

    def complete(target, preposing)
      line = "#{preposing}#{target}"

      if line.start_with?("/") && !preposing.include?(" ")
        return command_names.select { |c| c.start_with?(line) }
      end

      if preposing.start_with?("/") && preposing.include?(" ")
        cmd_name = preposing.delete_prefix("/").split(" ", 2).first
        return complete_command_args(cmd_name, target)
      end

      complete_files(target)
    end

    def command_names
      @commands.respond_to?(:names) ? @commands.names : @commands
    end

    def complete_command_args(cmd_name, partial)
      return [] unless @commands.respond_to?(:completions_for)

      @commands.completions_for(cmd_name, partial)
    end

    def complete_files(target)
      result = Elelem.sh("bash", args: ["-c", "compgen -f #{target}"])
      result[:content].lines.map(&:strip).first(20)
    end
  end
end
