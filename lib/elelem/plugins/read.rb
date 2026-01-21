# frozen_string_literal: true

Elelem::Plugins.register(:read) do |toolbox|
  toolbox.add("read",
    description: "Read file",
    params: { path: { type: "string" } },
    required: ["path"],
    aliases: ["open"]
  ) do |a|
    path = Pathname.new(a["path"]).expand_path
    path.exist? ? { content: path.read, path: a["path"] } : { error: "not found" }
  end

  toolbox.after("read") do |_, result|
    if result[:error]
      $stdout.puts "  ! #{result[:error]}"
    else
      system("bat", "--style=plain", "--paging=never", result[:path])
    end
  end
end
