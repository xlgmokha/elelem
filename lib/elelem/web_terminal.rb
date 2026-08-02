# frozen_string_literal: true

module Elelem
  class WebTerminal
    def initialize
      @subscribers = []
      @mutex = Mutex.new
      @answers = Queue.new
    end

    def subscribe
      Queue.new.tap { |queue| @mutex.synchronize { @subscribers << queue } }
    end

    def unsubscribe(queue)
      @mutex.synchronize { @subscribers.delete(queue) }
    end

    def interactive?
      true
    end

    def quiet?
      false
    end

    def say(text)
      emit("content", text)
    end

    def print(text)
      emit("content", text)
    end

    def think(text)
      emit("thinking", text)
      nil
    end

    def markdown(text)
      text
    end

    def display_file(path, fallback: nil)
      say(fallback || path)
    end

    def ask(prompt)
      emit("prompt", prompt)
      @answers.pop
    end

    def answer(text)
      @answers << text
    end

    def done
      broadcast(type: "done")
    end

    def waiting; end

    def gap; end

    def newline(n: 1); end

    private

    def emit(type, text)
      plain = text.to_s.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
      return if plain.strip.empty?

      broadcast(type: type, text: plain)
    end

    def broadcast(event)
      @mutex.synchronize { @subscribers.each { |queue| queue << event } }
    end
  end
end
