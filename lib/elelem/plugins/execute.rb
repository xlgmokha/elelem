# frozen_string_literal: true

Elelem::Plugins.register(:execute) do |toolbox|
  toolbox.add("execute",
    description: "Run shell command (supports pipes and redirections)",
    params: { command: { type: "string" } },
    required: ["command"],
    aliases: ["bash", "sh", "exec"]
  ) do |a|
    Elelem.sh("bash", args: ["-c", a["command"]]) { |x| $stdout.print(x) }
  end
end
