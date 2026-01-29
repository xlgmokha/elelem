# frozen_string_literal: true

Elelem::Plugins.register(:context) do |agent|
  agent.commands.register("context", description: "Show conversation context") do |args|
    messages = agent.context

    case args
    when nil, ""
      messages.each_with_index do |msg, i|
        role = msg[:role]
        preview = msg[:content].to_s.lines.first&.strip&.slice(0, 60) || ""
        preview += "..." if msg[:content].to_s.length > 60
        agent.terminal.say "  #{i + 1}. #{role}: #{preview}"
      end
    when "json"
      agent.terminal.say JSON.pretty_generate(messages)
    when /^\d+$/
      index = args.to_i - 1
      if index >= 0 && index < messages.length
        content = messages[index][:content].to_s
        agent.terminal.say(agent.terminal.markdown(content))
      else
        agent.terminal.say "  Invalid index: #{args}"
      end
    else
      agent.terminal.say "  Usage: /context [json|<number>]"
    end
  end
end
