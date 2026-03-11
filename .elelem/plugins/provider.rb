# frozen_string_literal: true

Elelem::Plugins.register(:provider) do |agent|
  agent.commands.register("provider", description: "Switch provider", completions: -> { Elelem::Providers.names }) do |name|
    if name.nil? || name.empty?
      agent.terminal.say "  → available: #{Elelem::Providers.names.join(", ")}"
    else
      agent.client = Elelem::Providers.build(name)
      agent.terminal.say "  → switched to #{name}"
    end
  end
end
