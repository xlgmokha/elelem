# frozen_string_literal: true

Elelem::Plugins.register(:eval) do |agent|
  description = <<~'DESC'
    Evaluate Ruby code. Available API:

    name = "search"
    agent.toolbox.add(name, description: "Search using rg", params: { query: { type: "string" } }, required: ["query"], aliases: []) do |args|
      agent.toolbox.run("execute", { "command" => "rg --json -nI -F #{args["query"]}" })
    end
  DESC

  agent.toolbox.add("eval",
    description: description,
    params: { ruby: { type: "string" } },
    required: ["ruby"]
  ) do |args|
    { result: binding.eval(args["ruby"]) }
  end
end
