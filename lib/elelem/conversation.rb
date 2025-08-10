# frozen_string_literal: true

module Elelem
  class Conversation
    SYSTEM_MESSAGE = <<~SYS
      You are ChatGPT, a helpful assistant with reasoning capabilities.
      Current date: #{Time.now.strftime("%Y-%m-%d")}.
      System info: `uname -a` output: #{`uname -a`.strip}
      Reasoning: high
    SYS

    ROLES = [:system, :user, :tool].freeze

    def initialize(items = [{ role: "system", content: SYSTEM_MESSAGE }])
      @items = items
    end

    def history
      @items
    end

    # :TODO truncate conversation history
    def add(role: user, content: "")
      raise "unknown role: #{role}" unless ROLES.include?(role.to_sym)

      @items << { role: role, content: content }
    end
  end
end
