# Plugins

Plugins extend elelem with custom functionality. There are four types:

| Type | Purpose | Registry |
|------|---------|----------|
| [Tool](authoring.md#tool-plugins) | Functions the LLM can call | `agent.toolbox.add` |
| [Command](authoring.md#command-plugins) | Slash commands for the user | `agent.commands.register` |
| [Hook](authoring.md#hook-plugins) | Before/after tool execution | `agent.toolbox.before/after` |
| [Provider](authoring.md#provider-plugins) | LLM backends | `Elelem::Providers.register` |

## Location

- `~/.elelem/plugins/` - user global (all projects)
- `.elelem/plugins/` - project local

## Basic Structure

```ruby
# ~/.elelem/plugins/myplugin.rb
Elelem::Plugins.register(:myplugin) do |agent|
  # add tools, commands, hooks
end
```

## Guides

- [Authoring](authoring.md) - step-by-step plugin creation
- [Examples](examples.md) - real plugins from the codebase
