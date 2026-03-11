# frozen_string_literal: true

Elelem::Plugins.register(:list) do |agent|
  agent.toolbox.add("list",
    description: "List directory contents",
    params: { path: { type: "string" }, recursive: { type: "boolean" } },
    required: [],
    aliases: ["ls"]
  ) do |a|
    path = a["path"] && !a["path"].empty? ? a["path"] : "."
    flags = a["recursive"] ? "-laR" : "-la"
    agent.toolbox.exec("ls", flags, path)
  end
end
