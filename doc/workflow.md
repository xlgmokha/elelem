# ELELEM-WORKFLOW(7)

## NAME

elelem-workflow - the plan/design/build/review/verify cycle

## DESCRIPTION

Elelem supports a structured workflow for feature development, inspired by
agile practices. Each phase has a dedicated mode that adjusts the system
prompt and available tools.

## WORKFLOW DIAGRAM

```
                    +--------+
                    |  Plan  |
                    +---+----+
                        |
                        v
                    +--------+
                    | Design |
                    +---+----+
                        |
                        v
                    +--------+
                    | Build  |
                    +---+----+
                        |
                        v
                    +--------+
                    | Review |
                    +---+----+
                        |
                        v
                    +--------+
                    | Verify |
                    +--------+
```

## PHASES

### Plan

Create user stories in `.elelem/backlog/`. Each story is a markdown file
with acceptance criteria and tasks.

Example story:

```markdown
# Add logout button

As a user, I want to log out so that I can end my session.

## Acceptance Criteria

- [ ] Button visible when logged in
- [ ] Click logs user out
- [ ] Redirects to home page

## Tasks

(filled in during design phase)
```

### Design

Research and plan implementation. The agent explores the codebase, identifies
extension points, and breaks the story into atomic tasks.

```
/mode design
```

Constraints:
- Allowed: read, glob, grep, task, execute (read-only)
- Blocked: code changes, test changes
- Can only edit files in .elelem/backlog/

### Build

Execute tasks from the story using TDD:

1. Write failing test
2. Implement minimal code to pass
3. Refactor if needed
4. Mark task complete

```
/mode build
```

All tools available. Work through tasks one at a time.

### Review

Verify changes meet acceptance criteria:

```
/mode review
```

The agent checks:
- All tasks completed
- Acceptance criteria satisfied
- Tests exist and pass
- No logic errors or security issues
- SOLID principles followed

### Verify

Demo the feature as if presenting to the Product Owner:

```
/mode verify
```

The agent performs end-to-end testing from the user's perspective and
documents the results.

## STORY FILES

Stories live in `.elelem/backlog/` and follow this structure:

```markdown
# Story Title

Brief description of the feature.

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Tasks

* [ ] Task 1
* [ ] Task 2
* [x] Completed task

## Demo Notes

Verified: 2026-01-15
Status: ACCEPTED

Observations:
- Feature works as expected
- Edge case X handled correctly
```

## SWITCHING MODES

Use the `/mode` command:

```
/mode              # show current mode
/mode build        # switch to build mode
/mode design       # switch to design mode
```

## SEE ALSO

elelem-modes(7), elelem-plugins(7)
