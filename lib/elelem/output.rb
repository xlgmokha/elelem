# frozen_string_literal: true

module Elelem
  class Output
    def initialize(stream: $stdout, **)
      @stream = stream
    end

    def say(text, as: nil)
      return if blank?(text)

      write "#{render(text, as)}\n"
    end

    def print(text)
      return if blank?(text)

      write text
    end

    def thinking(text)
      print("\e[2;3m#{text}\e[0m") unless blank?(text)
    end

    def doing(name, args, state: "+")
      say "#{state} \e[36m#{name}\e[0m(#{args})"
    end

    def waiting
    end

    def display_file(path, fallback: nil)
      say(fallback || path)
    end

    private

    def render(text, as)
      case as
      when :error
        return "error: #{text}"
      when :markdown
        "```\n" + text + "\n```\n"
      else
        text
      end
    end

    def write(text)
      @stream.print text
    end

    def blank?(text)
      text.nil? || text.to_s.strip.empty?
    end
  end
end
