# frozen_string_literal: true

Elelem::Plugins.register(:execute) do |agent|
  agent.toolbox.add("execute",
    description: "Run shell command (supports pipes and redirections)",
    params: { command: { type: "string" } },
    required: ["command"],
    aliases: ["bash", "sh", "exec", "execute<|channel|>"]
  ) do |a|
    Elelem.sh("bash", args: ["-c", a["command"]]) { |x| agent.terminal.print(x) }
  end

  agent.toolbox.after("execute") do |args, result|
    next if result[:exit_status] == 0

    agent.terminal.say agent.toolbox.header("execute", args, state: "x")
  end
end
