# frozen_string_literal: true

Elelem::Plugins.register(:tools) do |agent|
  agent.commands.register("tools", description: "List available tools") do
    agent.toolbox.tools.each_value do |tool|
      agent.terminal.say ""
      agent.terminal.say "  #{tool.name}"
      agent.terminal.say "    #{tool.description}"
      tool.params.each { |k, v| agent.terminal.say "      #{k}: #{v[:type] || v["type"]}" }
      agent.terminal.say "    aliases: #{tool.aliases.join(", ")}" if tool.aliases.any?
    end
  end
end
