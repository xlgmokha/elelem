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
      "\e[2m#{text}\e[0m"
    end

    def markdown(text)
      width = $stdout.winsize[1] rescue 80
      IO.popen(["glow", "-s", "dark", "-w", width.to_s, "-"], "r+") do |io|
        io.write(text)
        io.close_write
        io.read
      end
    rescue Errno::ENOENT
      text
    end

    def print(message)
      stop_dots
      $stdout.print message
    end

    def say(message)
      stop_dots
      $stdout.puts message
    end

    def newline
      say("")
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
      result[:output].lines.map(&:strip).first(20)
    end
  end
end
