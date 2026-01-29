# frozen_string_literal: true

Elelem::Plugins.register(:shell) do |agent|
  strip_ansi = ->(text) do
    text
      .gsub(/^Script started.*?\n/, "")
      .gsub(/\nScript done.*$/, "")
      .gsub(/\e\].*?(?:\a|\e\\)/, "")
      .gsub(/\e\[[0-9;?]*[A-Za-z]/, "")
      .gsub(/\e[PX^_].*?\e\\/, "")
      .gsub(/\e./, "")
      .gsub(/[\b]/, "")
      .gsub(/\r/, "")
  end

  agent.commands.register("shell", description: "Start interactive shell") do
    transcript = Tempfile.create do |file|
      system("script", "-q", file.path, chdir: Dir.pwd)
      strip_ansi.call(File.read(file.path))
    end
    agent.conversation.add(role: "user", content: transcript) unless transcript.strip.empty?
  end
end
