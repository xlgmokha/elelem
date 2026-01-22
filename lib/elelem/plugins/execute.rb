# frozen_string_literal: true

Elelem::Plugins.register(:execute) do |toolbox|
  toolbox.add("execute",
    description: "Run shell command (supports pipes and redirections)",
    params: { command: { type: "string" } },
    required: ["command"],
    aliases: ["bash", "sh", "exec", "execute<|channel|>"]
  ) do |a|
    Elelem.sh("bash", args: ["-c", a["command"]]) { |x| $stdout.print(x) }
  end

  toolbox.after("execute") do |args, result|
    status = result[:exit_status] == 0 ? "✓" : "x"
    $stdout.puts toolbox.header("execute", args, state: status)
  end
end
