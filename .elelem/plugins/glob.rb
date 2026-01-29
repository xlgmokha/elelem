# frozen_string_literal: true

Elelem::Plugins.register(:glob) do |agent|
  agent.toolbox.add("glob",
    description: "Find files matching pattern",
    params: { pattern: { type: "string" }, path: { type: "string" } },
    required: ["pattern"]
  ) do |a|
    path = a["path"] || "."
    result = agent.toolbox.exec("fd", "--glob", a["pattern"], path)
    result[:ok] ? result : agent.toolbox.exec("find", path, "-name", a["pattern"])
  end
end
