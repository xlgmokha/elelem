# frozen_string_literal: true

Elelem::Plugins.register(:confirm) do |agent|
  permissions = Elelem::Permissions.new

  agent.toolbox.before do |args, tool_name:|
    permissions.check(tool_name, args, terminal: agent.terminal)
  end
end
