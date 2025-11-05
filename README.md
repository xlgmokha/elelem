# Elelem

Fast, correct, autonomous - Pick two

PURPOSE:

Elelem is a minimal coding agent written in Ruby. It is intended to
assist me (a software engineer and computer science student) with writing,
editing, and managing code and text files from the command line. It acts
as a direct interface to an LLM, providing it with a simple text-based
UI and access to the local filesystem.

DESIGN PRINCIPLES:

- Follows the Unix philosophy: simple, composable, minimal.
- Convention over configuration.
- Avoids unnecessary defensive checks, or complexity.
- Assumes a mature and responsible LLM that behaves like a capable engineer.
- Designed for my workflow and preferences.
- Efficient and minimal like aider - https://aider.chat/
- UX like Claude Code - https://docs.claude.com/en/docs/claude-code/overview

SYSTEM ASSUMPTIONS:

- This script is used on a Linux system with the following tools: Alacritty, tmux, Bash, and Vim.
- It is always run inside a Git repository.
- All project work is assumed to be version-controlled with Git.
- Git is expected to be available and working; no checks are necessary.

SCOPE:

- This program operates only on code and plain-text files.
- It does not need to support binary files.
- The LLM has full access to execute system commands.
- There are no sandboxing, permission, or validation layers.
- Execution is not restricted or monitored - responsibility is delegated to the LLM.

CONFIGURATION:

- Avoid adding configuration options unless absolutely necessary.
- Prefer hard-coded values that can be changed later if needed.
- Only introduce environment variables after repeated usage proves them worthwhile.

UI EXPECTATIONS:

- The TUI must remain simple, fast, and predictable.
- No mouse support or complex UI components are required.
- Interaction is strictly keyboard-driven.

CODING STANDARDS FOR LLM:

- Do not add error handling or logging unless it is essential for functionality.
- Keep methods short and single-purpose.
- Use descriptive, conventional names.
- Stick to Ruby's standard library whenever possible.

HELPFUL LINKS:

- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- https://www.anthropic.com/engineering/writing-tools-for-agents
- https://simonwillison.net/2025/Sep/30/designing-agentic-loops/

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add elelem
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install elelem
```

## Usage

Start an interactive chat session with an Ollama model:

```bash
elelem chat
```

### Options

- `--host`: Specify Ollama host (default: localhost:11434)
- `--model`: Specify Ollama model (default: gpt-oss, currently only tested with gpt-oss)  
- `--token`: Provide authentication token

### Examples

```bash
# Chat with default model
elelem chat

# Chat with specific model and host
elelem chat --model llama2 --host remote-host:11434
```

### Features

- **Interactive REPL**: Clean command-line interface for chatting
- **Tool Execution**: Execute shell commands when requested by the AI
- **Streaming Responses**: Real-time streaming of AI responses
- **State Machine**: Robust state management for different interaction modes
- **Conversation History**: Maintains context across the session

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
