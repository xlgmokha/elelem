# Plugin Examples

Real plugins from the elelem codebase.

## Tool with After Hook

The `read` plugin displays file contents after reading:

```ruby
Elelem::Plugins.register(:read) do |agent|
  agent.toolbox.add("read",
    description: "Read file",
    params: { path: { type: "string" } },
    required: ["path"],
    aliases: ["open"]
  ) do |a|
    path = Pathname.new(a["path"]).expand_path
    path.exist? ? { content: path.read, path: a["path"] } : { error: "not found" }
  end

  agent.toolbox.after("read") do |_, result|
    if result[:error]
      agent.terminal.say "  ! #{result[:error]}"
    else
      agent.terminal.display_file(result[:path], fallback: result[:content])
    end
  end
end
```

## Context Compaction Command

The `compact` command summarizes conversation history:

```ruby
Elelem::Plugins.register(:compact) do |agent|
  agent.commands.register("compact", description: "Compress context") do
    response = agent.turn("Summarize: accomplishments, state, next steps. Brief.")
    agent.conversation.clear!
    agent.conversation.add(role: "user", content: "Context: #{response}")
    agent.terminal.say "  → compacted"
  end
end
```

## Tool Chaining

The `verify` plugin runs syntax checks and tests by calling other tools:

```ruby
module Elelem
  module Verifiers
    SYNTAX = {
      ".rb" => "ruby -c %{path}",
      ".py" => "python -m py_compile %{path}",
      ".go" => "go vet %{path}",
      ".ts" => "npx tsc --noEmit %{path}",
      ".js" => "node --check %{path}",
    }.freeze

    def self.for(path)
      cmds = []
      ext = File.extname(path)
      cmds << (SYNTAX[ext] % { path: path }) if SYNTAX[ext]
      cmds << test_runner
      cmds.compact
    end

    def self.test_runner
      %w[bin/test script/test].find { |s| File.executable?(s) }
    end
  end

  Plugins.register(:verify) do |agent|
    agent.toolbox.add("verify",
      description: "Verify file syntax and run tests",
      params: { path: { type: "string" } },
      required: ["path"]
    ) do |a|
      path = a["path"]
      Verifiers.for(path).inject({verified: []}) do |memo, cmd|
        agent.terminal.say agent.toolbox.header("execute", { "command" => cmd })
        v = agent.toolbox.run("execute", { "command" => cmd })
        break v.merge(path: path, command: cmd) if v[:exit_status] != 0

        memo[:verified] << cmd
        memo
      end
    end
  end
end
```

## Mode Switcher with Completion

```ruby
Elelem::Plugins.register(:mode) do |agent|
  agent.commands.register("mode",
    description: "Switch system prompt mode",
    completions: -> { Elelem::SystemPrompt.available_modes }
  ) do |args|
    name = args&.strip
    if name.nil? || name.empty?
      current = agent.system_prompt.mode
      modes = Elelem::SystemPrompt.available_modes.map { |m| m == current ? "*#{m}" : m }
      agent.terminal.say modes.join(" ")
    else
      agent.system_prompt.switch(name)
      agent.terminal.say "mode: #{name}"
    end
  end
end
```

## Provider Plugin

The Ollama provider:

```ruby
Elelem::Providers.register(:ollama) do
  Elelem::Net::Ollama.new(
    model: ENV.fetch("OLLAMA_MODEL", "gpt-oss:latest"),
    host: ENV.fetch("OLLAMA_HOST", "localhost:11434")
  )
end
```

## MCP Tool Output Formatting

Pretty-print JSON from MCP tools:

```ruby
Elelem::Plugins.register(:gitlab) do |agent|
  agent.toolbox.after("gitlab_search") do |_args, result|
    IO.popen(["jq", "-C", "."], "r+") do |io|
      io.write(result.to_json)
      io.close_write
      agent.terminal.say(io.read)
    end
  end
end
```

## Builtin Commands

Simple commands for common operations:

```ruby
Elelem::Plugins.register(:builtins) do |agent|
  agent.commands.register("exit", description: "Exit elelem") { exit(0) }

  agent.commands.register("clear", description: "Clear conversation history") do
    agent.conversation.clear!
    agent.terminal.say "  → context cleared"
  end

  agent.commands.register("help", description: "Show available commands") do
    agent.terminal.say agent.commands.map { |name, desc| "#{name.ljust(12)} #{desc}" }.join("\n")
  end
end
```
