# frozen_string_literal: true

Elelem::Plugins.register(:confirm) do |agent|
  permissions = Elelem::Permissions.new

  agent.toolbox.tools.each_key do |tool_name|
    agent.toolbox.before(tool_name) do |args|
      permissions.check(tool_name, args, terminal: agent.terminal)
    end
  end
end
