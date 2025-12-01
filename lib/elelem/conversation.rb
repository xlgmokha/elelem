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

    def dump(mode)
      JSON.pretty_generate(history_for(mode))
    end

    private

    def default_context(prompt = system_prompt_for([]))
      [{ role: "system", content: prompt }]
    end

    def system_prompt_for(mode)
      base = system_prompt

      case mode.sort
      when [:read]
        "#{base}\n\nYou may read files on the system."
      when [:write]
        "#{base}\n\nYou may write files on the system."
      when [:execute]
        "#{base}\n\nYou may execute shell commands on the system."
      when [:read, :write]
        "#{base}\n\nYou may read and write files on the system."
      when [:execute, :read]
        "#{base}\n\nYou may execute shell commands and read files on the system."
      when [:execute, :write]
        "#{base}\n\nYou may execute shell commands and write files on the system."
      when [:execute, :read, :write]
        "#{base}\n\nYou may read files, write files and execute shell commands on the system."
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
