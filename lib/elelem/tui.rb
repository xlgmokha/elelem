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

    private

    def colourize(text, colour: :default)
      case colour
      when :gray
        "\e[90m#{text}\e[0m"
      else
        text
      end
    end
  end
end
