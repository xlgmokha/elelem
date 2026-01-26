# frozen_string_literal: true

Elelem::Plugins.register(:gitlab) do |agent|
  agent.toolbox.after("gitlab_search") do |_args, result|
    agent.terminal.say result.inspect
  end
end
