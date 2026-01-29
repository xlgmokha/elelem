# frozen_string_literal: true

Elelem::Plugins.register(:tools) do |agent|
  completions = -> { agent.toolbox.tools.keys }

  agent.commands.register("tools", description: "List available tools", completions: completions) do |arg|
    if arg && !arg.empty?
      tool = agent.toolbox.tools[arg]
      unless tool
        agent.terminal.say "Unknown tool: #{arg}"
        next
      end

      lines = ["## #{tool.name}", "", tool.description, "", "### Parameters", ""]
      tool.params.each do |name, spec|
        req = tool.required.include?(name.to_s) ? ", required" : ""
        desc = spec[:description] ? " - #{spec[:description]}" : ""
        lines << "- `#{name}` (#{spec[:type]}#{req})#{desc}"
      end
      lines << "" << "*aliases: #{tool.aliases.join(", ")}*" if tool.aliases.any?

      agent.terminal.say agent.terminal.markdown(lines.join("\n"))
    else
      rows = agent.toolbox.tools.each_value.map do |tool|
        "| #{tool.name} | #{tool.description.lines.first.chomp} |"
      end

      md = String.new("| Tool | Description |\n")
      md << "|------|-------------|\n"
      md << rows.join("\n")

      agent.terminal.say agent.terminal.markdown(md)
    end
  end
end
