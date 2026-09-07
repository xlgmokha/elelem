As an `agent`, I `want to ask questions with different answer types`, so that `I can collect structured responses while still allowing conversational flexibility`.

# SYNOPSIS

Add support for text, single-select, multi-select, and yes/no question types to the interview tool.

# DESCRIPTION

The interview tool currently only supports free-form text input. This story adds support for four question types:

1. **text** - Open-ended free-form input (current behavior)
2. **single** - Single selection from a list of options (radio-button style)
3. **multi** - Multiple selections from a list of options (checkbox style)
4. **yesno** - Boolean yes/no confirmation

Even when structured options are presented, the user can always type free-form text instead. The agent should handle unexpected responses gracefully (e.g., if the user asks a clarifying question rather than selecting an option).

Example API:
```ruby
interview(
  question: "Pick a color",
  type: "single",
  options: ["Red", "Green", "Blue"]
)
```

# SEE ALSO

* [ ] lib/elelem/terminal.rb - Terminal input/output handling
* [ ] lib/elelem/tool.rb - Tool definition structure

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Agent can specify `type: "text"` for free-form input (default behavior)
* [ ] Agent can specify `type: "single"` with `options` array for single selection
* [ ] Agent can specify `type: "multi"` with `options` array for multiple selection
* [ ] Agent can specify `type: "yesno"` for boolean confirmation
* [ ] Options are displayed as a numbered list (e.g., "1. Red", "2. Green", "3. Blue")
* [ ] User can type a number to select an option
* [ ] User can type free-form text instead of selecting a numbered option
* [ ] For multi-select, user can enter comma-separated numbers (e.g., "1, 3")
* [ ] For yes/no, accepts variations like "y", "yes", "n", "no" (case-insensitive)
* [ ] Response returned to agent includes both the raw input and parsed selection(s)
