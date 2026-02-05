As a `user`, I `want consistent blank line spacing in terminal output`, so that `the interface feels polished and predictable`.

# SYNOPSIS

Audit and standardize blank lines between all terminal output sections.

# DESCRIPTION

Currently, the number of blank lines between sections varies depending on the
order of events during a session. Sometimes there are 2 blank lines, sometimes
1, leading to an inconsistent visual experience.

This story involves:
1. Auditing all places that write to the terminal
2. Establishing spacing rules (e.g., 1 blank line between sections)
3. Ensuring consistent application of those rules

# DESIGN

**Root cause:** Spacing is caller-side (each method decides its own prefix/suffix spacing)
instead of boundary-aware (spacing happens at transitions).

**Scenarios causing inconsistency:**
- Dots running → `stop_dots` adds newline + `markdown` adds 2 newlines = 3 lines
- No dots → `markdown` adds 2 newlines = 2 lines  
- `header` returns `\n...` + `say` adds newline = double spacing

**Solution:** One flag (`@at_line_start`), one method (`gap`).

`gap` is idempotent: "ensure we're at a blank line". Call it anywhere between 
sections. If already at line start, it's a no-op. If mid-content, it adds one newline.

**Changes:**
- Terminal tracks cursor state via `@at_line_start`
- `gap` method: `newline unless @at_line_start`
- `markdown` uses `gap` instead of `newline(n: 2)`
- `header` drops its `\n` prefix (caller uses `gap`)

**Trade-offs:**
- Simplicity ✓ - 1 flag, 1 method, 3 file changes
- No plugin changes needed - existing `say`/`print` calls just work
- Idempotent - safe to call `gap` multiple times

# SEE ALSO

* [ ] lib/elelem/terminal.rb - Primary output methods (say, print, markdown, newline)
* [ ] lib/elelem/agent.rb - REPL loop and turn processing with terminal calls
* [ ] lib/elelem/toolbox.rb - header() method prepends \n to output
* [ ] lib/elelem/plugins/read.rb - after hook uses terminal.say and display_file
* [ ] lib/elelem/plugins/write.rb - after hook uses terminal.say and display_file
* [ ] lib/elelem/plugins/execute.rb - streaming print and after hook
* [ ] lib/elelem/plugins/tools.rb - markdown output for tool listings
* [ ] lib/elelem/plugins/context.rb - multi-line output for context display
* [ ] lib/elelem/plugins/builtins.rb - /clear and /help command output
* [ ] lib/elelem/plugins/provider.rb - provider switching messages

# Tasks

## Terminal (lib/elelem/terminal.rb)
* [x] Add `@at_line_start = true` in initialize
* [x] Add `gap` method: `newline unless @at_line_start` (idempotent blank line)
* [x] Update `say` to set `@at_line_start = true` after output
* [x] Update `print` to set `@at_line_start = false` (mid-line content)
* [x] Update `newline` to set `@at_line_start = true`
* [x] Update `stop_dots` - already calls newline, will inherit correct state
* [x] Update `markdown` - replace `newline(n: 2)` with `gap`

## Toolbox (lib/elelem/toolbox.rb)
* [x] Update `header` - remove leading `\n` from return string

## Agent (lib/elelem/agent.rb)
* [x] Add `terminal.gap` before `terminal.say toolbox.header(...)` in process method

## Testing
* [x] Add spec for `gap` idempotence: calling twice produces one blank line
* [ ] Visual audit: conversation with tool calls
* [ ] Visual audit: multi-tool execution
* [ ] Visual audit: streaming execute output

# Acceptance Criteria

* [ ] Single blank line between distinct output sections
* [ ] No double blank lines appear in any scenario
* [ ] No missing blank lines between sections
* [ ] Spacing is consistent regardless of event order
* [ ] Visual audit of common workflows passes
