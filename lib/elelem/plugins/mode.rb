# frozen_string_literal: true

Elelem::Plugins.register(:mode) do |agent|
  agent.commands.register("mode",
    description: "Switch system prompt mode",
    completions: -> { Elelem::SystemPrompt.available_modes }
  ) do |args|
    name = args&.strip
    if name.nil? || name.empty?
      current = agent.system_prompt.mode
      modes = Elelem::SystemPrompt.available_modes.map { |m| m == current ? "*#{m}" : m }
      agent.terminal.say modes.join(" ")
    else
      agent.system_prompt.switch(name)
      agent.terminal.say "mode: #{name}"
    end
  end

  agent.commands.register("compact", description: "Compress context") do
    response = agent.turn("Summarize: accomplishments, state, next steps. Brief.")
    agent.conversation.clear!
    agent.conversation.add(role: "user", content: "Context: #{response}")
    agent.terminal.say "  → compacted"
  end
end
