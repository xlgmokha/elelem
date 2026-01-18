# frozen_string_literal: true

module Elelem
  class Terminal
    def initialize(commands: [])
      @commands = commands
      @dots_thread = nil
      setup_completion
    end

    def ask(prompt)
      Reline.readline(prompt, true)&.strip
    end

    def dim(text)
      return if blank?(text)

      "\e[2m#{text}\e[0m"
    end

    def markdown(text)
      return if blank?(text)

      newline
      width = $stdout.winsize[1] rescue 80
      IO.popen([
        "bat",
        "--squeeze-blank",
        "--style=plain",
        "--paging=never",
        "--force-colorization",
        "--language=markdown",
        "--theme=auto:always",
        "--terminal-width=#{width}",
        "-"
      ], "r+") do |io|
        io.write(text)
        io.close_write
        io.read
      end
    rescue Errno::ENOENT
      text
    end

    def print(text)
      return if blank?(text)

      stop_dots
      $stdout.print text
    end

    def say(text)
      return if blank?(text)

      stop_dots
      $stdout.puts text
    end

    def newline
      $stdout.puts("")
    end

    def file(path)
      Elelem.sh("bat", args: [
        "--style=plain",
        "--paging=never",
        "--color=always",
        path
      ]) { |x| $stdout.print(x) }
    end

    def waiting
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
      text.nil? || text.strip.empty?
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
      return @commands.select { |c| c.start_with?(line) } if line.start_with?("/") && !preposing.include?(" ")

      complete_files(target)
    end

    def complete_files(target)
      result = Elelem.sh("bash", args: ["-c", "compgen -f #{target}"])
      result[:content].lines.map(&:strip).first(20)
    end
  end
end
