# frozen_string_literal: true

Elelem::Plugins.register(:builtins) do |agent|
  agent.commands.register("exit", description: "Exit elelem") { exit(0) }

  agent.commands.register("clear", description: "Clear conversation history") do
    agent.conversation.clear!
    agent.terminal.say "  → context cleared"
  end

  agent.commands.register("context", description: "Show conversation context") do
    agent.terminal.say JSON.pretty_generate(agent.context)
  end

  agent.commands.register("shell", description: "Start interactive shell") do
    transcript = Tempfile.create do |file|
      system("script", "-q", file.path, chdir: Dir.pwd)
      File.read(file.path)
        .gsub(/^Script started.*?\n/, "")
        .gsub(/\nScript done.*$/, "")
        .gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
        .gsub(/\e\[\?[0-9]+[hl]/, "")
        .gsub(/[\b]/, "")
        .gsub(/\r/, "")
    end
    agent.conversation.add(role: "user", content: transcript) unless transcript.strip.empty?
  end

  agent.commands.register("init", description: "Generate AGENTS.md") do
    system_prompt = <<~PROMPT
      AGENTS.md generator. Analyze codebase and write AGENTS.md to project root.

      # AGENTS.md Spec (https://agents.md/)
      A file providing context and instructions for AI coding agents.

      ## Recommended Sections
      - Commands: build, test, lint commands
      - Code Style: conventions, patterns
      - Architecture: key components and flow
      - Testing: how to run tests

      ## Process
      1. Read README.md if present
      2. Identify language (Gemfile, package.json, go.mod)
      3. Find test scripts (bin/test, npm test)
      4. Check linter configs
      5. Write concise AGENTS.md

      Keep it minimal. No fluff.
    PROMPT

    agent.fork(system_prompt: system_prompt).turn("Generate AGENTS.md for this project")
  end

  agent.commands.register("reload", description: "Reload plugins and source") do
    lib_dir = File.expand_path("../..", __dir__)
    original_verbose, $VERBOSE = $VERBOSE, nil
    Dir["#{lib_dir}/**/*.rb"].sort.each { |f| load(f) }
    $VERBOSE = original_verbose
    agent.toolbox = Elelem::Toolbox.new
    agent.commands = Elelem::Commands.new
    Elelem::Plugins.reload!(agent)
  end

  agent.commands.register("help", description: "Show available commands") do
    agent.terminal.say agent.commands.names.join(" ")
  end
end
