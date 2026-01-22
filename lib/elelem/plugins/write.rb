# frozen_string_literal: true

Elelem::Plugins.register(:write) do |toolbox|
  toolbox.add("write",
    description: "Write file",
    params: { path: { type: "string" }, content: { type: "string" } },
    required: ["path", "content"]
  ) do |a|
    path = Pathname.new(a["path"]).expand_path
    FileUtils.mkdir_p(path.dirname)
    { bytes: path.write(a["content"]), path: a["path"] }
  end

  toolbox.after("write") do |_, result|
    if result[:error]
      $stdout.puts "  ! #{result[:error]}"
    elsif !system("bat", "--paging=never", result[:path])
      $stdout.puts "  -> #{result[:path]}"
    end
  end
end
