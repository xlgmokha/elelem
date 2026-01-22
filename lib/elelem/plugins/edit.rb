# frozen_string_literal: true

Elelem::Plugins.register(:edit) do |toolbox|
  toolbox.add("edit",
    description: "Replace first occurrence of text in file",
    params: { path: { type: "string" }, old: { type: "string" }, new: { type: "string" } },
    required: ["path", "old", "new"]
  ) do |a|
    path = Pathname.new(a["path"]).expand_path
    content = path.read
    if content.include?(a["old"])
      toolbox.run("write", {
        "path" => a["path"],
        "content" => content.sub(a["old"], a["new"])
      })
    else
      { error: "text not found", content: content.lines.first(20).join }
    end
  end
end
