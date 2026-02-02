# Configuration

Elelem uses convention over configuration. Most behavior comes from file locations and environment variables.

## Directory Structure

**User global** (`~/.elelem/`):
- `plugins/` - plugins loaded for all projects
- `mcp.json` - global MCP servers

**Project local** (`.elelem/`):
- `plugins/` - project-specific plugins
- `prompts/` - custom mode templates (ERB)
- `backlog/` - user stories for workflow
- `mcp.json` - project MCP servers

## Plugin Loading Order

1. `lib/elelem/plugins/` (built-in)
2. `~/.elelem/plugins/` (user global)
3. `.elelem/plugins/` (project local)

Later plugins override earlier ones. Plugins starting with `zz_` load last.

## Project Instructions

`AGENTS.md` provides project-specific instructions. Elelem searches up the directory tree from the current working directory.
