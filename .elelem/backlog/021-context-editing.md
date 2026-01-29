As a `user`, I `want to view, delete, and edit context entries`, so that `I can manually prune or summarize the conversation`.

# SYNOPSIS

`/context` command to list, delete, and edit conversation entries.

# DESCRIPTION

As conversations grow, the context can become bloated with irrelevant
entries or verbose tool output. The user should be able to:

1. **View** context as a numbered list with role and preview
2. **Delete** entries interactively or by number
3. **Edit** a single entry in `$EDITOR`

Example session:
```
> /context
1. [system] You are a developer... (245 tokens)
2. [user] Fix the login bug
3. [assistant] I'll look at auth.rb... (89 tokens)
4. [tool] read auth.rb → 450 lines (1200 tokens)
5. [assistant] The issue is on line 42... (156 tokens)

> /context delete
  [ ] 1. [system] You are a developer...
  [x] 4. [tool] read auth.rb → 450 lines
  
Deleted 1 entry.

> /context edit 3
# Opens entry 3 in $EDITOR, saves changes back to context
```

# SEE ALSO

* [ ] lib/elelem/conversation.rb - Context storage
* [ ] lib/elelem/commands.rb - Slash command registry
* [ ] .elelem/backlog/009-enhanced-interview-tool.md - Multi-select UI
* [ ] .elelem/backlog/019-interruptibility.md - Related workflow

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] `/context` shows numbered list with role and preview
* [ ] Each entry shows approximate token count
* [ ] `/context delete` opens interactive multi-select
* [ ] `/context delete 3,4,5` deletes by number
* [ ] `/context edit N` opens entry N in `$EDITOR`
* [ ] Edited content replaces original entry
* [ ] Empty edit (delete all content) removes the entry
* [ ] System prompt (entry 1) protected from deletion
* [ ] Changes reflected immediately in conversation
