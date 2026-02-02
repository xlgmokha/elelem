# ELELEM-MODE-BUILD(7)

## NAME

elelem-mode-build - implementation with TDD

## SYNOPSIS

```
/mode build
```

## DESCRIPTION

Build mode is the primary implementation mode. The agent works through tasks
from a story using test-driven development: write a failing test, implement
minimal code to pass, then refactor.

## ROLE

- Work through Tasks in the specified story
- Check off completed tasks
- Follow TDD: write failing test, implement, refactor

## TOOLS

All tools are available:

| Tool | Purpose |
|------|---------|
| read(path) | Read file contents |
| write(path, content) | Create or overwrite file |
| edit(path, old, new) | Replace text in file |
| execute(command) | Run shell command |
| eval(ruby) | Execute Ruby code |
| task(prompt) | Delegate to sub-agent |
| verify(path) | Check syntax and run tests |

## PROCESS

1. **Focus** - Ask which story to work on if not specified
2. **Read** - Load the story from .elelem/backlog/
3. **Test** - Write failing test first
4. **Implement** - Minimal code to pass
5. **Verify** - Run tests
6. **Check** - Mark task complete in story file

## EDITING TECHNIQUES

Multi-line changes:

```
echo "DIFF" | patch -p1
```

Single-line changes:

```
sed -i'' 's/old/new/' file
```

New files: use the write tool

## SEARCH COMMANDS

```
rg -n "pattern" .           # text search
fd -e rb .                  # file discovery
sg -p 'def $NAME' -l ruby   # structural search
```

## TASK COMPLETION

When a task is done, edit the story file:

```markdown
# Tasks

* [x] Create FooService in lib/foo_service.rb  <- mark done
* [ ] Add #bar method to handle X              <- next task
```

## GUIDELINES

- Work on what the user asks for
- One task at a time
- Minimal diffs
- No defensive code
- Verify after every change

## SEE ALSO

elelem-modes(7), elelem-mode-review(7)
