# Elelem

Fast, correct, autonomous – pick two.

## Purpose

Elelem is a minimal coding agent written in Ruby. It is designed to help
you write, edit, and manage code and plain-text files from the command line
by delegating work to an LLM. The agent exposes a simple text-based UI and a
set of built-in tools that give the LLM access to the local file system
and Git.

## Design Principles

* Unix philosophy – simple, composable, minimal.
* Convention over configuration.
* No defensive checks or complexity beyond what is necessary.
* Assumes a mature, responsible LLM that behaves like a capable engineer.
* Optimised for my personal workflow and preferences.
* Efficient and minimal like *aider* – https://aider.chat/.
* UX similar to Claude Code – https://docs.claude.com/en/docs/claude-code/overview.

## System Assumptions

* Linux host with Alacritty, tmux, Bash, Vim.
* Runs inside a Git repository.
* Git is available and functional.

## Scope

Only plain-text and source-code files are supported. No binary handling,
sandboxing, or permission checks are performed - the LLM has full access.

## Configuration

Prefer convention over configuration. Add environment variables only after
repeated use proves their usefulness.

## UI Expectations

Keyboard-driven, minimal TUI. No mouse support or complex widgets.

## Coding Standards for the LLM

* No extra error handling unless essential.
* Keep methods short, single-purpose.
* Descriptive, conventional names.
* Use Ruby standard library where possible.

## Helpful Links

* https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
* https://www.anthropic.com/engineering/writing-tools-for-agents
* https://simonwillison.net/2025/Sep/30/designing-agentic-loops/

## Installation

Install the gem directly:

```bash
gem install elelem
```

## Usage

Start an interactive chat session with an Ollama model:

```bash
elelem chat
```

### Options

* `--host` – Ollama host (default: `localhost:11434`).
* `--model` – Ollama model (default: `gpt-oss`).
* `--token` – Authentication token.

### Examples

```bash
# Default model
elelem chat

# Specific model and host
elelem chat --model llama2 --host remote-host:11434
```

## Mode System

The agent exposes seven built‑in tools. You can switch which ones are
available by changing the *mode*:

| Mode    | Enabled Tools                            |
|---------|------------------------------------------|
| plan    | `grep`, `list`, `read`                   |
| build   | `grep`, `list`, `read`, `patch`, `write` |
| verify  | `grep`, `list`, `read`, `execute`        |
| auto    | All tools                                |

Use the following commands inside the REPL:

```text
/mode plan    # Read‑only
/mode build   # Read + Write
/mode verify  # Read + Execute
/mode auto    # All tools
/mode         # Show current mode
```

The system prompt is adjusted per mode so the LLM knows which actions
are permissible.

## Features

* **Interactive REPL** – clean, streaming chat.
* **Toolbox** – file I/O, Git, shell execution.
* **Streaming Responses** – output appears in real time.
* **Conversation History** – persists across turns; can be cleared.
* **Context Dump** – `/context` shows the current conversation state.

## Toolbox Overview

The `Toolbox` class is defined in `lib/elelem/toolbox.rb`. It supplies
seven tools, each represented by a JSON schema that the LLM can call.

| Tool      | Purpose                              | Parameters                           |
| ----      | -------                              | ----------                           |
| `bash`    | Run shell commands                   | `cmd`, `args`, `env`, `cwd`, `stdin` |
| `eval`    | Dynamically create new tools         | `code`                               |
| `grep`    | Search Git‑tracked files             | `query`                              |
| `list`    | List tracked files                   | `path` (optional)                    |
| `patch`   | Apply a unified diff via `git apply` | `diff`                               |
| `read`    | Read file contents                   | `path`                               |
| `write`   | Overwrite a file                     | `path`, `content`                    |

## Tool Definition

The core `Tool` wrapper is defined in `lib/elelem/tool.rb`. Each tool is
created with a name, description, JSON schema for arguments, and a block
that performs the operation. The LLM calls a tool by name and passes the
arguments as a hash.

## Known Limitations

* Assumes the current directory is a Git repository.
* No sandboxing – the LLM can run arbitrary commands.
* Error handling is minimal; exceptions are returned as an `error` field.

## Contributing

Feel free to open issues or pull requests. The repository follows the
GitHub Flow.

## License

MIT – see the bundled `LICENSE.txt`.
