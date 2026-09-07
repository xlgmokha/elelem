# Elelem

Fast, correct, autonomous - pick two.

## Purpose

Elelem is a minimal coding harness written in Ruby.
It is designed to help you write, edit, and manage code and plain-text files from the command line by delegating work to an LLM.
The agent exposes a simple text-based UI and a set of built-in tools that give the LLM access to the local file system.

## Design Principles

* Unix philosophy – simple, composable, minimal.
* Convention over configuration.
* No defensive checks or complexity beyond what is necessary.
* Assumes a mature, responsible LLM that behaves like a capable engineer.
* Optimised for my personal workflow and preferences.
* Efficient and minimal like *aider* – https://aider.chat/.
* UX similar to Claude Code – https://docs.claude.com/en/docs/claude-code/overview.

## System Assumptions

Elelem relies on several external tools. Install the ones you need:

| Tool | Purpose | Install |
|------|---------|---------|
| [git](https://git-scm.com/) | Version control | `brew install git` / `apt install git` |
| [glow](https://github.com/charmbracelet/glow) | Markdown rendering | `brew install glow` / `go install github.com/charmbracelet/glow@latest` |

## Coding Standards for the LLM

* No extra error handling unless essential.
* Keep methods short, single-purpose.
* Descriptive, conventional names.
* Use Ruby standard library where possible.

## Installation

Install the gem directly:

```bash
gem install elelem
```

## Usage

Start an interactive chat session:

```bash
elelem chat
```

## Tools

Built-in tools available to the LLM:

| Tool      | Purpose                    | Parameters                |
| --------- | -------------------------- | ------------------------- |
| `read`    | Read file contents         | `path`                    |
| `write`   | Write file                 | `path`, `content`         |
| `execute` | Run shell command          | `command`                 |

Use the plugin API to add more tools.

## Contributing

```bash
$ git clone https://git.mokhan.ca/xlgmokha/elelem.git
```

Send me a patch via email. For instructions see https://git-send-email.io/.

## License

MIT – see the bundled `LICENSE.txt`.
