# frozen_string_literal: true

Elelem::Plugins.register(:git) do |agent|
  allowed = %w[status diff log show branch checkout add reset stash].freeze

  agent.toolbox.add("git",
    description: "Run git command",
    params: { command: { type: "string" }, args: { type: "array" } },
    required: ["command"]
  ) do |a|
    cmd = a["command"]
    next { error: "not allowed: #{cmd}" } unless allowed.include?(cmd)

    agent.toolbox.exec("git", cmd, *(a["args"] || []))
  end

  agent.toolbox.after("git") do |_, result|
    agent.terminal.say "  ! #{result[:error]}" if result[:error]
  end
end
