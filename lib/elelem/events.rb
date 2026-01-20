# frozen_string_literal: true

module Elelem
  module Events
    @handlers = Hash.new { |h, k| h[k] = [] }

    class << self
      def on(event, &block)
        @handlers[event] << block
      end

      def emit(event, **payload)
        @handlers[event].each { |h| h.call(payload) }
      end

      def clear(event = nil)
        event ? @handlers.delete(event) : @handlers.clear
      end

      def handlers
        @handlers
      end
    end
  end

  def self.on(event, &block)
    Events.on(event, &block)
  end

  def self.emit(event, **payload)
    Events.emit(event, **payload)
  end
end
