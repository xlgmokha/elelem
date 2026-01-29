# frozen_string_literal: true

Elelem::Plugins.register(:tools) do |agent|
  agent.commands.register("tools", description: "List available tools") do
    md = agent.toolbox.tools.each_value.map do |tool|
      lines = ["- **#{tool.name}** - #{tool.description.lines.first.chomp}"]

      tool.params.each do |name, spec|
        req = tool.required.include?(name.to_s) ? ", required" : ""
        desc = spec[:description] ? " - #{spec[:description]}" : ""
        lines << "  - `#{name}` (#{spec[:type]}#{req})#{desc}"
      end

      lines << "  - aliases: #{tool.aliases.join(", ")}" if tool.aliases.any?
      lines.join("\n")
    end.join("\n\n")

    agent.terminal.say agent.terminal.markdown(md)
  end
end
