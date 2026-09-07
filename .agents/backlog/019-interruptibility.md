As a `user`, I `want to interrupt the agent with CTRL+C`, so that `I can stop and redirect when the agent goes off track`.

# SYNOPSIS

CTRL+C stops generation, discards partial response, returns to fresh prompt.

# DESCRIPTION

When the agent is generating a response or executing tools, the user may
realize it's going in the wrong direction. Currently, interruption behavior
may be inconsistent or leave the conversation in an awkward state.

Desired behavior:
1. User presses CTRL+C during agent response
2. Generation stops immediately
3. Partial response is discarded (not added to context)
4. User returns to a fresh prompt
5. User can then redirect, edit context, or continue

This pairs well with context editing (story 020) - after interrupting,
the user may want to prune context before continuing.

# SEE ALSO

* [ ] lib/elelem/agent.rb - Response handling, REPL
* [ ] lib/elelem/conversation.rb - Context management
* [ ] Signal handling for SIGINT
* [ ] .elelem/backlog/020-context-editing.md - Related feature

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] CTRL+C stops agent response immediately
* [ ] Partial response is not added to conversation context
* [ ] User returns to fresh prompt after interrupt
* [ ] Tool execution in progress is cancelled cleanly
* [ ] No orphaned processes or broken state after interrupt
* [ ] Multiple rapid CTRL+C presses handled gracefully
* [ ] Clear visual indication that response was interrupted
