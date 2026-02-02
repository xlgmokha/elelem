# Getting Started

## First Run

```
gem install elelem
cd your-project
elelem chat
```

Elelem requires a git repository and an LLM provider. By default it uses Ollama on localhost:11434.

## Your First Conversation

```
you: What files are in this project?
```

The agent uses its tools to explore and respond. Type `/help` to see available commands.

## Project Instructions

Create an `AGENTS.md` file at your repository root to give the agent project-specific instructions:

```markdown
# Project Instructions

- Use 2 spaces for indentation
- Run `bin/test` after changes
- Follow TDD
```

Elelem searches up the directory tree for this file.

## Next Steps

- [Workflow](workflow.md) - learn the development cycle
- [Configuration](configuration.md) - customize elelem
- [Plugins](plugins/) - extend with custom tools
