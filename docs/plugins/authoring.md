# Plugin Authoring

Step-by-step guides for creating each plugin type.

## Tool Plugins

Tools are functions the LLM can call. The LLM sees the tool name, description, and parameter schema.

### Step 1: Create the file

```ruby
# ~/.elelem/plugins/weather.rb
Elelem::Plugins.register(:weather) do |agent|
end
```

### Step 2: Define the tool

```ruby
Elelem::Plugins.register(:weather) do |agent|
  agent.toolbox.add("weather",
    description: "Get current weather for a city",
    params: {
      city: { type: "string", description: "City name" }
    },
    required: ["city"]
  ) do |args|
    # Tool implementation
  end
end
```

### Step 3: Implement the logic

The block receives `args` (a Hash) and must return a Hash:

```ruby
agent.toolbox.add("weather",
  description: "Get current weather for a city",
  params: {
    city: { type: "string", description: "City name" }
  },
  required: ["city"]
) do |args|
  city = args["city"]
  response = Net::HTTP.get(URI("https://wttr.in/#{city}?format=j1"))
  data = JSON.parse(response)
  {
    city: city,
    temp_c: data.dig("current_condition", 0, "temp_C"),
    condition: data.dig("current_condition", 0, "weatherDesc", 0, "value")
  }
end
```

### Step 4: Add output formatting (optional)

Use an after hook to display results to the user:

```ruby
agent.toolbox.after("weather") do |_args, result|
  agent.terminal.say "  #{result[:city]}: #{result[:temp_c]}°C, #{result[:condition]}"
end
```

### Complete example

```ruby
# ~/.elelem/plugins/weather.rb
Elelem::Plugins.register(:weather) do |agent|
  agent.toolbox.add("weather",
    description: "Get current weather for a city",
    params: {
      city: { type: "string", description: "City name" }
    },
    required: ["city"]
  ) do |args|
    city = args["city"]
    response = Net::HTTP.get(URI("https://wttr.in/#{city}?format=j1"))
    data = JSON.parse(response)
    {
      city: city,
      temp_c: data.dig("current_condition", 0, "temp_C"),
      condition: data.dig("current_condition", 0, "weatherDesc", 0, "value")
    }
  end

  agent.toolbox.after("weather") do |_args, result|
    agent.terminal.say "  #{result[:city]}: #{result[:temp_c]}°C, #{result[:condition]}"
  end
end
```

---

## Command Plugins

Commands are slash commands invoked by the user (not the LLM).

### Step 1: Create the file

```ruby
# ~/.elelem/plugins/todo.rb
Elelem::Plugins.register(:todo) do |agent|
end
```

### Step 2: Register the command

```ruby
Elelem::Plugins.register(:todo) do |agent|
  agent.commands.register("todo", description: "Show todo list") do |args|
    # Command implementation
  end
end
```

The block receives the argument string after the command name.

### Step 3: Implement the logic

```ruby
agent.commands.register("todo", description: "Manage todo list") do |args|
  case args&.strip
  when nil, ""
    todos = File.readlines("TODO.md").map(&:strip)
    agent.terminal.say todos.join("\n")
  when /^add (.+)/
    File.open("TODO.md", "a") { |f| f.puts "- [ ] #{$1}" }
    agent.terminal.say "  → added"
  end
end
```

### Step 4: Add tab completion (optional)

```ruby
agent.commands.register("todo",
  description: "Manage todo list",
  completions: -> { %w[add done list] }
) do |args|
  # ...
end
```

### Complete example

```ruby
# ~/.elelem/plugins/todo.rb
Elelem::Plugins.register(:todo) do |agent|
  agent.commands.register("todo",
    description: "Manage todo list",
    completions: -> { %w[add list] }
  ) do |args|
    case args&.strip
    when nil, "", "list"
      if File.exist?("TODO.md")
        agent.terminal.say File.read("TODO.md")
      else
        agent.terminal.say "  (no todos)"
      end
    when /^add (.+)/
      File.open("TODO.md", "a") { |f| f.puts "- [ ] #{$1}" }
      agent.terminal.say "  → added"
    end
  end
end
```

---

## Hook Plugins

Hooks run before or after tool execution. Use them for logging, confirmation, or post-processing.

### Before hooks

Run before a tool executes. Return `false` to cancel execution.

**Tool-specific:**

```ruby
Elelem::Plugins.register(:logger) do |agent|
  agent.toolbox.before("execute") do |args|
    File.open("commands.log", "a") { |f| f.puts args["command"] }
  end
end
```

**Global (all tools):**

```ruby
Elelem::Plugins.register(:audit) do |agent|
  agent.toolbox.before do |args, tool_name:|
    File.open("audit.log", "a") { |f| f.puts "#{Time.now} #{tool_name}" }
  end
end
```

### After hooks

Run after a tool completes. Receive both args and result.

**Tool-specific:**

```ruby
Elelem::Plugins.register(:notify) do |agent|
  agent.toolbox.after("execute") do |args, result|
    if result[:exit_status] != 0
      system("notify-send", "Command failed", args["command"])
    end
  end
end
```

**Global:**

```ruby
Elelem::Plugins.register(:timing) do |agent|
  starts = {}

  agent.toolbox.before do |_args, tool_name:|
    starts[tool_name] = Time.now
  end

  agent.toolbox.after do |_args, _result, tool_name:|
    elapsed = Time.now - starts[tool_name]
    agent.terminal.say "  (#{tool_name}: #{elapsed.round(2)}s)"
  end
end
```

### Confirmation hook

A common pattern is requiring confirmation before dangerous operations:

```ruby
# Name starts with zz_ to load last
# ~/.elelem/plugins/zz_confirm.rb
Elelem::Plugins.register(:confirm) do |agent|
  agent.toolbox.before("execute") do |args|
    agent.terminal.say "  run: #{args["command"]}"
    response = agent.terminal.ask("  proceed? [y/n] ")
    response.strip.downcase == "y"
  end
end
```

---

## Provider Plugins

Providers are LLM backends. They implement the `fetch` interface.

### Step 1: Create the client class

The client must implement:

```ruby
fetch(messages, tools = []) { |event| ... } -> Array<tool_calls>
```

**Messages** (OpenAI format):

```ruby
{ role: "system", content: "..." }
{ role: "user", content: "..." }
{ role: "assistant", content: "..." }
{ role: "tool", tool_call_id: "...", content: "..." }
```

**Tools** (OpenAI format):

```ruby
{ type: "function", function: { name:, description:, parameters: } }
```

**Events** (yield to block):

```ruby
{ type: "saying", text: "..." }      # assistant response text
{ type: "thinking", text: "..." }    # reasoning/thinking text
{ type: "tool_call", id:, name:, arguments: }
```

**Return value:**

```ruby
[{ id: "...", name: "tool_name", arguments: { ... } }, ...]
```

### Step 2: Create the provider plugin

```ruby
# ~/.elelem/plugins/gemini.rb
require_relative "gemini_client"

Elelem::Providers.register(:gemini) do
  GeminiClient.new(
    model: ENV.fetch("GEMINI_MODEL", "gemini-pro"),
    api_key: ENV.fetch("GEMINI_API_KEY")
  )
end
```

### Step 3: Implement the client

```ruby
# ~/.elelem/plugins/gemini_client.rb
class GeminiClient
  def initialize(model:, api_key:)
    @model = model
    @api_key = api_key
  end

  def fetch(messages, tools = [])
    tool_calls = []

    # Convert messages to Gemini format
    body = build_request(messages, tools)

    # Stream response
    stream(body) do |chunk|
      # Parse chunk and yield events
      if chunk["text"]
        yield(type: "saying", text: chunk["text"])
      end

      if chunk["functionCall"]
        tc = parse_tool_call(chunk["functionCall"])
        yield(type: "tool_call", **tc)
        tool_calls << tc
      end
    end

    tool_calls
  end

  private

  def build_request(messages, tools)
    # Convert to Gemini API format
    {
      contents: messages.map { |m| convert_message(m) },
      tools: tools.map { |t| convert_tool(t) }
    }
  end

  def stream(body)
    # POST to Gemini API with streaming
    # Parse SSE events and yield chunks
  end

  def parse_tool_call(fc)
    {
      id: SecureRandom.uuid,
      name: fc["name"],
      arguments: fc["args"]
    }
  end
end
```

### Complete minimal example

```ruby
# ~/.elelem/plugins/echo.rb
# A mock provider for testing

class EchoClient
  def fetch(messages, tools = [])
    last = messages.last[:content]
    yield(type: "saying", text: "You said: #{last}")
    []
  end
end

Elelem::Providers.register(:echo) do
  EchoClient.new
end
```

Use with: `elelem chat --provider echo`

---

## Agent API Reference

Plugins receive an `agent` object with:

| Method | Description |
|--------|-------------|
| `agent.toolbox` | Add tools and hooks |
| `agent.commands` | Register slash commands |
| `agent.terminal` | Output to user (`say`, `ask`, `markdown`) |
| `agent.conversation` | Access message history |
| `agent.client` | Current LLM client |
| `agent.fork(system_prompt:)` | Create sub-agent |
| `agent.turn(prompt)` | Get LLM response |
