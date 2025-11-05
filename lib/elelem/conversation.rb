# frozen_string_literal: true

module Elelem
  class Conversation
    ROLES = %i[system assistant user tool].freeze

    def initialize(items = default_context)
      @items = items
    end

    def history_for(mode)
      history = @items.dup
      history[0] = { role: "system", content: system_prompt_for(mode) }
      history
    end

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

    def clear
      @items = default_context
    end

    def dump
      JSON.pretty_generate(@items)
    end

    private

    def default_context(prompt = system_prompt_for([]))
      [{ role: "system", content: prompt }]
    end

    def system_prompt_for(mode)
      base = system_prompt

      case mode.sort
      when [:read]
        "#{base}\n\nRead and analyze. Understand before suggesting action."
      when [:write]
        "#{base}\n\nWrite clean, thoughtful code."
      when [:execute]
        "#{base}\n\nUse shell commands creatively to understand and manipulate the system."
      when [:read, :write]
        "#{base}\n\nFirst understand, then build solutions that integrate well."
      when [:read, :execute]
        "#{base}\n\nUse commands to deeply understand the system."
      when [:write, :execute]
        "#{base}\n\nCreate and execute freely. Have fun. Be kind."
      when [:read, :write, :execute]
        "#{base}\n\nYou have all tools. Use them wisely."
      else
        base
      end
    end

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
