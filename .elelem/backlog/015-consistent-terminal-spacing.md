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

# SEE ALSO

* [ ] lib/elelem/terminal.rb - Primary output methods
* [ ] lib/elelem/agent.rb - May have direct output calls

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Single blank line between distinct output sections
* [ ] No double blank lines appear in any scenario
* [ ] No missing blank lines between sections
* [ ] Spacing is consistent regardless of event order
* [ ] Visual audit of common workflows passes
