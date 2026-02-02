# ELELEM-MODE-DESIGN(7)

## NAME

elelem-mode-design - research and plan implementation

## SYNOPSIS

```
/mode design
```

## DESCRIPTION

Design mode focuses the agent on researching and planning implementation for
backlog stories. The agent explores the codebase, identifies patterns and
extension points, then breaks stories into atomic tasks.

## ROLE

- Read stories from `.elelem/backlog/`
- Explore codebase to understand existing patterns
- Fill in the Tasks section of each story
- Identify risks and dependencies

## CONSTRAINTS

**Allowed:**
- read, glob, grep, task
- execute (read-only commands)
- edit (only files in .elelem/backlog/)

**Blocked:**
- Code changes
- Test changes

## PROCESS

1. **Review** - Read stories in .elelem/backlog/
2. **Explore** - Trace code paths, find extension points
3. **Research** - Consider design options and trade-offs
4. **Plan** - Break each story into implementation tasks
5. **Update** - Edit story files to add Tasks

## TASK FORMAT

Tasks should be added to the story's `# Tasks` section:

```markdown
# Tasks

* [ ] Create FooService in lib/foo_service.rb
* [ ] Add #bar method to handle X
* [ ] Write spec in spec/foo_service_spec.rb
* [ ] Update config/routes.rb to add endpoint
```

## GUIDELINES

- Tasks should be small, atomic, and independently testable
- Order tasks by dependency (do X before Y)
- Reference specific files to modify
- Note if new files are needed
- Consider test-first ordering

## TRADE-OFF DIMENSIONS

When designing, consider:

- Simplicity vs Flexibility
- Performance vs Readability
- Coupling vs Cohesion

## SEE ALSO

elelem-modes(7), elelem-mode-build(7)
