As a `user`, I `want to navigate options with arrow keys`, so that `I can quickly select from a list without typing numbers`.

# SYNOPSIS

Add TUI-style interactive selection widgets for single and multi-select questions.

# DESCRIPTION

When the terminal supports it, present single-select and multi-select questions as interactive widgets where the user can:

- Use **arrow keys** (up/down) to navigate between options
- Press **space** to toggle selection (for multi-select)
- Press **enter** to confirm selection

This provides a smoother experience than typing numbers, especially for longer option lists. The numbered fallback (from story 006) remains available for terminals that don't support the TUI widgets or when the user starts typing text instead of navigating.

The widget should be visually clear:
- Highlight the currently focused option
- Show a marker (e.g., `[x]` or `●`) for selected options
- For single-select, selection and confirmation can be combined (enter selects and confirms)

# SEE ALSO

* [ ] .elelem/backlog/006-interview-question-types.md - Prerequisite: question types with numbered fallback
* [ ] lib/elelem/terminal.rb - Terminal capabilities and input handling
* [ ] Reline library - May provide building blocks for TUI input

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Single-select questions show an interactive list when terminal supports it
* [ ] User can press up/down arrows to move highlight between options
* [ ] User can press enter to select the highlighted option (single-select)
* [ ] Multi-select questions allow space to toggle selection on highlighted option
* [ ] Multi-select shows visual indicator for selected items (e.g., `[x]`)
* [ ] Pressing enter on multi-select confirms current selections
* [ ] If user starts typing text, widget gracefully switches to free-form input mode
* [ ] Falls back to numbered list input if terminal doesn't support TUI features
* [ ] Works correctly when terminal is resized during interaction
