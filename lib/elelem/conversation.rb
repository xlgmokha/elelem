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
        "#{base}\n\n## MODE: plan (read-only)\nFocus on EXPLORE and UNDERSTAND phases. Research thoroughly before suggesting solutions. No implementation yet."
      when [:write]
        "#{base}\n\n## MODE: write-only\nWrite clean code. Cannot execute or verify with tests."
      when [:execute]
        "#{base}\n\n## MODE: execute-only\nUse shell commands creatively to understand and manipulate the system. Cannot modify files."
      when [:read, :write]
        "#{base}\n\n## MODE: build (read + write)\nFollow full workflow: EXPLORE → PLAN → EXECUTE. Verify syntax after changes. Cannot run tests with bash."
      when [:execute, :read]
        "#{base}\n\n## MODE: verify (read + execute)\nUse commands to deeply understand the system. Run tests and checks. Cannot modify files."
      when [:execute, :write]
        "#{base}\n\n## MODE: write + execute\nCreate and execute freely. VERIFY your changes by running tests."
      when [:execute, :read, :write]
        "#{base}\n\n## MODE: auto (full autonomy)\nYou have all tools. Follow complete workflow: EXPLORE → PLAN → EXECUTE → VERIFY. Run tests after changes."
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
