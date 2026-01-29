# frozen_string_literal: true

Elelem::Plugins.register(:grep) do |agent|
  agent.toolbox.add("grep",
    description: "Search file contents",
    params: { pattern: { type: "string" }, path: { type: "string" }, glob: { type: "string" } },
    required: ["pattern"]
  ) do |a|
    path = a["path"] || "."
    glob = a["glob"]
    rg_args = ["rg", "-n", a["pattern"], path]
    rg_args += ["-g", glob] if glob
    result = agent.toolbox.exec(*rg_args)
    next result if result[:ok]

    grep_args = ["grep", "-rn"]
    grep_args += ["--include", glob] if glob
    grep_args += [a["pattern"], path]
    agent.toolbox.exec(*grep_args)
  end
end
