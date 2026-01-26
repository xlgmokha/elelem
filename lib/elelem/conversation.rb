# frozen_string_literal: true

module Elelem
  class Conversation
    ROLES = %w[user assistant tool].freeze

    def initialize
      @messages = []
    end

    def add(role:, content:)
      raise ArgumentError, "invalid role: #{role}" unless ROLES.include?(role)
      @messages << { role: role, content: content }
    end

    def last = @messages.last
    def length = @messages.length
    def clear! = @messages.clear

    def to_a(system_prompt: nil)
      base = system_prompt ? [{ role: "system", content: system_prompt }] : []
      base + @messages
    end
  end
end
