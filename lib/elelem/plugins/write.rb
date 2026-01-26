# frozen_string_literal: true

Elelem::Plugins.register(:write) do |agent|
  agent.toolbox.add("write",
    description: "Write file",
    params: { path: { type: "string" }, content: { type: "string" } },
    required: ["path", "content"],
    aliases: ["write<|channel|>"]
  ) do |a|
    path = Pathname.new(a["path"]).expand_path
    FileUtils.mkdir_p(path.dirname)
    { bytes: path.write(a["content"]), path: a["path"] }
  end

  agent.toolbox.after("write") do |_, result|
    if result[:error]
      agent.terminal.say "  ! #{result[:error]}"
    else
      agent.terminal.display_file(result[:path], fallback: "  -> #{result[:path]}")
      agent.toolbox.run("verify", { "path" => result[:path] })
    end
  end
end
