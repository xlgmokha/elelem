# ADR-0001: Consolidate Local Inference Stories

**Date:** 2026-01-29
**Status:** Accepted

## Context

We have five related user stories (001-005) covering local inference capability:

| Story | Title | Dependencies |
|-------|-------|--------------|
| 001 | Local inference spike | None |
| 002 | Hardware detection | 001 |
| 003 | Model download | 001, 002 |
| 004 | Local inference provider | 001, 003 |
| 005 | Default provider selection | 004 |

Stories 002-005 have strict dependencies and only deliver value together. The spike (001) produces a different deliverable (research document + decision) than the implementation stories.

## Decision

Keep story 001 (spike) separate. Consolidate stories 002-005 into a single implementation story.

## Consequences

**Positive:**
- Clearer deliverable: one story = one working feature
- Spike/implementation separation follows established pattern
- Reduces backlog overhead from 5 stories to 2
- Easier to understand the end-to-end goal

**Negative:**
- Larger implementation story may be harder to estimate
- Less granular progress tracking during development
