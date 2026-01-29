As a `user`, I `want long output paged without losing scrollback`, so that `I can control reading pace AND copy full context from tmux later`.

# SYNOPSIS

Pipe output through `glow` for markdown rendering, then to a pager that preserves terminal scrollback.

# DESCRIPTION

When agent output is long, the user needs to control reading pace (pager behavior)
but also needs the full output preserved in terminal scrollback for later reference
(e.g., copying from tmux buffer, scrolling up to review earlier output).

## Flow

1. Agent starts streaming response
2. Output piped through `glow` (markdown rendering)
3. Rendered output piped to `less -RX` or `glow -p`
4. User reads with pager controls (j/k, space, etc.)
5. User quits pager (q)
6. **Full rendered output remains in terminal scrollback**
7. Next section/prompt appears below
8. User can scroll up in terminal/tmux and see everything

## Key Insight

Standard `less` uses "alternate screen" which hides output on exit.
The `-X` flag disables this, preserving output in scrollback.

Recommended pager: `less -RXF`
- `-R`: Preserve ANSI colors
- `-X`: Don't use alternate screen (preserve scrollback)
- `-F`: Quit immediately if content fits on screen

Or: `glow -p` (glow's built-in pager, need to verify scrollback behavior)

## Trigger

Pager activates when output exceeds terminal height.

# SEE ALSO

* [ ] lib/elelem/terminal.rb - Output methods
* [ ] `$PAGER` environment variable
* [ ] `IO.console.winsize` for terminal dimensions
* [ ] `glow` - Markdown rendering CLI
* [ ] `less -RXF` - Pager that preserves scrollback

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Long output pauses for reading (pager behavior)
* [ ] After quitting pager, full output visible in terminal scrollback
* [ ] tmux `capture-pane -p -S -` captures all previous output
* [ ] Markdown rendered via `glow` before paging
* [ ] ANSI colors preserved
* [ ] Short output prints directly (no pager overhead)
* [ ] Works correctly when stdout is not a TTY (no pager)
* [ ] Default pager: `less -RXF` (preserves scrollback)
* [ ] User can override with `$PAGER` (but should include `-X` equivalent)
* [ ] User can disable paging entirely via config
