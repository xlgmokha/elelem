As a `user`, I `want slash commands available at any prompt`, so that `I can use /shell or other commands when the agent asks me a question`.

# SYNOPSIS

Enable slash command processing at every `Terminal#ask` call, not just the main REPL.

# DESCRIPTION

Currently, slash commands like `/shell` only work at the main agent prompt.
When the agent asks a question (e.g., via the interview tool), the user
cannot access these commands.

Example scenario:
1. Agent asks: "Should I commit this to git?"
2. User types `/shell`
3. User drops into shell, runs `git commit -m "fix bug"`, exits
4. Shell history/output is captured and returned as the answer
5. Agent knows the user committed the changes

Behavior:
- All `Terminal#ask` calls should process slash commands
- `/shell` captures command history and output from the subshell
- Result is returned as the "answer" to the prompt
- Other commands (`/help`, `/context`, etc.) work contextually

# SEE ALSO

* [ ] lib/elelem/terminal.rb - `ask` method
* [ ] lib/elelem/commands.rb - Slash command registry
* [ ] lib/elelem/agent.rb - REPL command processing

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Slash commands recognized at any `Terminal#ask` prompt
* [ ] `/shell` drops user into interactive shell
* [ ] Shell session output/history captured on exit
* [ ] Captured output returned as the prompt answer
* [ ] `/help` shows available commands at any prompt
* [ ] Tab completion works for slash commands at any prompt
* [ ] Regular text input still works normally
