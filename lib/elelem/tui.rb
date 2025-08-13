# frozen_string_literal: true

module Elelem
  class TUI
    attr_reader :stdin, :stdout

    def initialize(stdin = $stdin, stdout = $stdout)
      @stdin = stdin
      @stdout = stdout
    end

    def prompt(message)
      say(message)
      stdin.gets&.chomp
    end

    def say(message, colour: :default, newline: false)
      formatted_message = colourize(message, colour: colour)
      if newline
        stdout.puts(formatted_message)
      else
        stdout.print(formatted_message)
      end
      stdout.flush
    end

    def show_progress(message, prefix = "[.]", colour: :gray)
      timestamp = current_time_string
      formatted_message = colourize("#{prefix} #{timestamp} #{message}", colour: colour)
      stdout.print(formatted_message)
      stdout.flush
    end

    def clear_line
      stdout.print("\r#{" " * 80}\r")
      stdout.flush
    end

    def complete_progress(message = "Completed")
      clear_line
      timestamp = current_time_string
      formatted_message = colourize("[✓] #{timestamp} #{message}", colour: :green)
      stdout.puts(formatted_message)
      stdout.flush
    end

    private

    def current_time_string
      Time.now.strftime("%H:%M:%S")
    end

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
