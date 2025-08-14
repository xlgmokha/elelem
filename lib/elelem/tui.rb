# frozen_string_literal: true

module Elelem
  class TUI
    attr_reader :stdin, :stdout

    def initialize(stdin = $stdin, stdout = $stdout)
      @stdin = stdin
      @stdout = stdout
    end

    def prompt(message)
      Reline.readline(message, true)
    end

    def say(message, colour: :default, newline: false)
      if newline
        stdout.puts(colourize(message, colour: colour))
      else
        stdout.print(colourize(message, colour: colour))
      end
      stdout.flush
    end

    def show_progress(message, icon = ".", colour: :gray)
      timestamp = Time.now.strftime("%H:%M:%S")
      say("[#{icon}] #{timestamp} #{message}", colour: colour, newline: false)
    end

    def clear_line
      say("\r#{" " * 80}\r", newline: false)
    end

    def complete_progress(message = "Completed")
      clear_line
      show_progress(message, "✓", colour: :green)
    end

    private

    def colourize(text, colour: :default)
      case colour
      when :black
        "\e[30m#{text}\e[0m"
      when :red
        "\e[31m#{text}\e[0m"
      when :green
        "\e[32m#{text}\e[0m"
      when :yellow
        "\e[33m#{text}\e[0m"
      when :blue
        "\e[34m#{text}\e[0m"
      when :magenta
        "\e[35m#{text}\e[0m"
      when :cyan
        "\e[36m#{text}\e[0m"
      when :white
        "\e[37m#{text}\e[0m"
      when :gray
        "\e[90m#{text}\e[0m"
      else
        text
      end
    end
  end
end
