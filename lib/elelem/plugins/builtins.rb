# frozen_string_literal: true

Elelem::Plugins.register(:builtins) do |agent|
  agent.commands.register("exit", description: "Exit elelem") { exit(0) }

  agent.commands.register("clear", description: "Clear conversation history") do
    agent.conversation.clear!
    agent.terminal.say "  → context cleared"
  end

  agent.commands.register("help", description: "Show available commands") do
    agent.terminal.say agent.commands.names.join(" ")
  end
end
