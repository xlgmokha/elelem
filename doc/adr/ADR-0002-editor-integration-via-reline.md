# ADR-0002: Editor Integration via Reline

**Date:** 2026-01-29
**Status:** Accepted

## Context

Users want the ability to open their `$EDITOR` from the prompt to compose
long or complex messages. The proposed approach was to implement `CTRL+x CTRL+e`
keybinding (matching Bash/Zsh behavior).

Research into Ruby's Reline library revealed that this functionality already
exists for vi mode users.

## Decision

Do not implement custom editor integration. Document the existing Reline
vi mode functionality instead.

**How it works today (vi mode):**
1. Configure vi mode in `~/.inputrc`: `set editing-mode vi`
2. At the elelem prompt, press `ESC` to enter command mode
3. Press `v` to open `$EDITOR` with current input
4. Edit, save, quit
5. Text returns to prompt

Reline's `vi_histedit` function handles:
- Creating temp file with current input
- Opening `$EDITOR`
- Reading result back into the prompt
- Cleanup

## Consequences

**Positive:**
- Zero application code required
- Leverages existing, well-tested functionality
- Consistent with standard vi behavior
- Works out of the box for vi mode users
- Respects user's `~/.inputrc` configuration

**Negative:**
- Emacs mode users don't get `CTRL+x CTRL+e` (no built-in equivalent)
- Requires users to know vi mode is available
- Documentation is the only deliverable

## References

- Reline source: `line_editor.rb` - `vi_histedit` method
- inputrc location priority: `$INPUTRC` → `~/.inputrc` → `$XDG_CONFIG_HOME/readline/inputrc`
