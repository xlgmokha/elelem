# frozen_string_literal: true

Elelem::Plugins.register(:gitlab) do |agent|
  agent.toolbox.after("gitlab_search") do |_args, result|
    agent.terminal.say(agent.terminal.markdown(result))
  end
end
