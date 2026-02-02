# ELELEM-MODES(7)

## NAME

elelem-modes - system prompt modes

## DESCRIPTION

Modes adjust the agent's system prompt and behavior for different phases of
development. Each mode focuses the agent on a specific task with appropriate
constraints.

## AVAILABLE MODES

| Mode | Purpose | Constraints |
|------|---------|-------------|
| design | Research and plan implementation | Read-only, can edit backlog |
| build | Execute tasks with TDD | All tools available |
| review | Verify changes meet criteria | Read-only analysis |
| verify | Demo feature to Product Owner | End-to-end testing |

## SWITCHING MODES

```
/mode              # show current mode and list all modes
/mode design       # switch to design mode
/mode build        # switch to build mode
```

## MODE DOCUMENTATION

* [design](design.md) - research and planning
* [build](build.md) - implementation with TDD
* [review](review.md) - code review against criteria
* [verify](verify.md) - end-to-end verification

## CUSTOM MODES

Create custom modes by adding ERB templates to `.elelem/prompts/`:

```
.elelem/prompts/mymode.erb
```

The template has access to these variables:

| Variable | Description |
|----------|-------------|
| `pwd` | Current working directory |
| `platform` | Operating system |
| `date` | Current date |
| `git_info` | Git branch and status |
| `repo_map` | Ctags-generated code map |
| `agents_md` | Contents of AGENTS.md |
| `elelem_source` | Path to elelem source |

Example custom mode:

```erb
You are in documentation mode. Write clear, concise docs.

# Role
- Generate documentation for code
- Follow the project's doc style

# Environment
pwd: <%= pwd %>
date: <%= date %>
<%= git_info %>
```

## SEE ALSO

elelem-workflow(7), elelem-plugins(7)
