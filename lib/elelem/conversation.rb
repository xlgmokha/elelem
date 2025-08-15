# frozen_string_literal: true

module Elelem
  class Conversation
    ROLES = %i[system assistant user tool].freeze

    def initialize(items = [{ role: "system", content: system_prompt }])
      @items = items
    end

    def history
      @items
    end

    # :TODO truncate conversation history
    def add(role: :user, content: "")
      role = role.to_sym
      raise "unknown role: #{role}" unless ROLES.include?(role)
      return if content.nil? || content.empty?

      if @items.last && @items.last[:role] == role
        @items.last[:content] += content
      else
        @items.push({ role: role, content: normalize(content) })
      end
    end

    private

    def system_prompt
      ERB.new(Pathname.new(__dir__).join("system_prompt.erb").read).result(binding)
    end

    def normalize(content)
      if content.is_a?(Array)
        content.join(", ")
      else
        content.to_s
      end
    end
  end
end
