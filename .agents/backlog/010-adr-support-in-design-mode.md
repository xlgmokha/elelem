As a `developer`, I `want design mode to support creating Architecture Decision Records`, so that `architectural decisions are documented consistently and repeatably`.

# SYNOPSIS

Add ADR creation capability to design mode with a standard template.

# DESCRIPTION

When architectural decisions emerge during design sessions, the agent should be able to create ADRs using a consistent template. ADRs are stored in `doc/adr/` and follow a numbered naming convention.

The design prompt should be updated to:
1. Explain when to create ADRs (significant architectural decisions)
2. Provide the ADR template
3. Allow writing to `doc/adr/` directory

# SEE ALSO

* [ ] lib/elelem/prompts/design.erb - Design mode prompt
* [ ] doc/adr/ - ADR storage location (to be created)

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Design mode prompt includes ADR template
* [ ] Design mode can write files to `doc/adr/`
* [ ] ADRs follow naming convention: `ADR-NNNN-short-name.md`
* [ ] Template includes: Date, Status, Context, Decision, Consequences
* [ ] Agent understands when to propose creating an ADR

# ADR Template

```markdown
# ADR-NNNN: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

**Positive:**
- Benefit 1
- Benefit 2

**Negative:**
- Tradeoff 1
- Tradeoff 2
```

# Guidance for Design Mode

Include in the prompt:

> **When to create an ADR:**
> - Choosing between multiple valid approaches
> - Adopting a new technology or pattern
> - Changing an existing architectural decision
> - Decisions that affect multiple components
>
> **When NOT to create an ADR:**
> - Implementation details within a single file
> - Bug fixes
> - Routine refactoring
