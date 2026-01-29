# frozen_string_literal: true

Elelem::Plugins.register(:init) do |agent|
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
end
