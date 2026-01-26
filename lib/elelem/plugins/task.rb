# frozen_string_literal: true

Elelem::Plugins.register(:task) do |agent|
  agent.toolbox.add("task",
    description: "Delegate subtask to focused agent (complex searches, multi-file analysis)",
    params: { prompt: { type: "string" } },
    required: ["prompt"]
  ) do |a|
    sub = Elelem::Agent.new(agent.client, toolbox: agent.toolbox, terminal: agent.terminal,
      system_prompt: "Research agent. Search, analyze, report. Be concise.")
    sub.turn(a["prompt"])
    { result: sub.conversation.last[:content] }
  end
end
