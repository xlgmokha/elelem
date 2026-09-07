# frozen_string_literal: true

module Elelem
  class StubProvider
    def fetch(messages, tools = [], &block)
      block.call(type: "thinking", text: "considering the request")
      return block.call(type: "saying", text: "done.") if messages.last[:role] == "tool"

      block.call(type: "saying", text: "let me check.")
      return unless (tool = tools.first)

      block.call(type: "doing", id: "stub-1", name: tool[:function][:name], arguments: {})
    end
  end
end
