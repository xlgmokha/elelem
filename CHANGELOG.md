## [0.9.0] - 2026-01-21

### Added
- **Plugin system** with support for custom tool definitions
  - Load plugins from `lib/elelem/plugins/`, `~/.elelem/plugins/`, and `.elelem/plugins/`
  - `Elelem::Plugins.register(name) { |toolbox| ... }` API
  - Built-in plugins: `read`, `write`, `edit`, `execute`, `eval`, `verify`, `confirm`, `mcp`
- **MCP (Model Context Protocol)** server support via `.mcp.json` configuration
- **AGENTS.md** file support - searches up directory tree for project instructions
- **`/init` command** to generate an AGENTS.md file for the current project
- **`/shell` command** to drop into a shell session and capture the transcript to context
- **`/reload` command** to hot-reload source code without restarting the process
- **`task` tool** for delegating subtasks to focused sub-agents
- **`edit` tool** for replacing first occurrence of text in a file
- **`eval` tool** for executing Ruby code and dynamically registering new tools
- **`verify` tool** for syntax checking and running project tests
- **Pre/post tool hooks** (`toolbox.before`/`toolbox.after`) for extensibility
- **Confirmation prompt** before executing shell commands (when TTY)
- **Context compaction** for long conversations (summarizes old messages)
- **Repo map** via ctags included in system prompt
- **Markdown rendering** with [glow](https://github.com/charmbracelet/glow) for LLM responses
- **CLI improvements**: optparse-based interface with `-p`/`-m` flags
  - `elelem chat` - Interactive REPL (default)
  - `elelem ask <prompt>` - One-shot query (reads stdin if piped)
  - `elelem files` - Output files as XML
- JSON Schema validation for tool call arguments (via `json_schemer`)
- Tool aliases support (e.g., `bash`, `sh`, `exec` → `execute`)
- **Dependencies documentation** in README with installation links

### Changed
- **Breaking**: Requires Ruby >= 4.0.0 (was 3.4.0)
- **Breaking**: Removed `net-llm` dependency - LLM clients now inline in `lib/elelem/net/`
  - `Elelem::Net::Claude` (Anthropic and Vertex AI)
  - `Elelem::Net::OpenAI`
  - `Elelem::Net::Ollama`
- **Breaking**: Simplified LLM client `fetch` contract
  - Yields `{content:, thinking:}` deltas
  - Returns `tool_calls` array directly
- **Breaking**: Tool schema uses OpenAI format (`{type: "function", function: {...}}`)
- **Breaking**: Tool definitions use `description:` key (was `desc:`)
- **Breaking**: Removed modes and permissions system entirely
- **Breaking**: Removed slash commands (`/mode`, `/env`, `/provider`, `/model`)
  - Remaining: `/clear`, `/context`, `/init`, `/reload`, `/shell`, `/exit`, `/help`
- **Breaking**: Removed many dependencies
  - Removed: `thor`, `cli-ui`, `erb`, `cgi`, `set`, `timeout`, `logger`, `net-llm`, `json-schema`
  - Added: `json_schemer`, `optparse`, `tempfile`, `stringio`, `uri`
- Consolidated multiple exe files into single `exe/elelem` entry point
- Tools are now defined via plugins instead of hardcoded in Toolbox
- System prompt includes hints for `rg`, `fd`, `sg` (ast-grep), `sed`, `patch`
- System prompt regenerated on each fetch (includes dynamic repo map)
- Default tool set: `read`, `write`, `edit`, `execute`, `eval`, `verify`, `task`
- System prompt encourages using `eval` to create tools for repetitive tasks

### Removed
- `lib/elelem/application.rb` - CLI now in `exe/elelem`
- `lib/elelem/conversation.rb` - simplified into Agent
- `lib/elelem/git_context.rb` - inlined into Agent
- `lib/elelem/system_prompt.erb` - now generated in Agent
- `web_fetch`, `web_search`, `fetch`, `search_engine` tools
- `patch` tool (use `edit` or `execute` with `sed`/`patch`)
- `grep`, `list` tools (use `execute` with `rg`, `fd`)
- Modes and permissions system
- Events module
- GitHub Actions CI workflow

### Fixed
- Handle missing args in Claude provider
- Tool alias resolution (use canonical tool name, not alias)
- Unknown tool error now suggests using `execute` and lists available tools
- Duplicate write operations in edit flow

## [0.8.0] - 2026-01-14

### Added
- `fetch` tool for HTTP GET requests (returns status and body)
- `search_engine` tool for DuckDuckGo Instant Answer API searches
- Tool aliases: `get`/`web` → `fetch`, `ddg`/`duckduckgo` → `search_engine`
- `net-hippie` and `cgi` dependencies for HTTP requests

## [0.7.0] - 2026-01-14

### Added
- ASCII spinner animation while waiting for LLM responses
- `Terminal#waiting` method with automatic cleanup on next output
- Decision-making principles in system prompt (prefer reversible actions, ask when uncertain)
- Mode enforcement tests

### Changed
- Renamed internal `mode` concept to `permissions` for clarity (read/write/execute are permissions, plan/build/verify are modes)
- Refactored `Toolbox#run_tool` to accept `permissions:` parameter

### Fixed
- **Security**: Mode restrictions now enforced at execution time, not just schema time
  - Previously, LLMs could call tools outside their mode by guessing tool names
  - Now `run_tool` validates the tool is allowed for the current permission set

## [0.6.0] - 2026-01-12

### Added
- `/env` slash command to capture environment variables for provider connections
- `/shell` slash command
- `/provider` and `/model` slash commands
- Tab completion for commands
- Help output for `/mode` and `/env` commands

### Changed
- Renamed `bash` tool to `exec`
- Tuned system prompt
- Changed thinking prompt to ellipsis
- Removed username from system prompt
- Use pessimistic constraint on net-llm dependency
- Extracted Terminal class for IO abstraction (enables E2E testing)

### Fixed
- Prevent infinite looping errors
- Provide function schema when tool is called with invalid arguments
- Tab completion for `pass` entries without requiring `show` subcommand
- Password store symlink support in tab completion

## [0.5.0] - 2026-01-07

### Added
- Multi-provider support: Ollama, Anthropic, OpenAI, and VertexAI
- `--provider` CLI option to select LLM provider (default: ollama)
- `--model` CLI option to override default model
- Tool aliases (`bash` also accepts `exec`, `shell`, `command`, `terminal`, `run`)
- Thinking text output for models that support extended thinking

### Changed
- Requires net-llm >= 0.5.0 with unified fetch interface
- Updated gem description to reflect multi-provider support

## [0.4.2] - 2025-12-01

### Changed
- Renamed `exec` tool to `bash` for clarity
- Improved system prompt with iterative refinements
- Added environment context variables to system prompt

## [0.4.1] - 2025-11-26

### Added
- `elelem files` subcommand: generates Claude‑compatible XML file listings.
- Rake task `files:prompt` to output a ready‑to‑copy list of files for prompts.

### Changed
- Refactor tool‑call formatting to a more compact JSON payload for better LLM parsing.
- Updated CI and documentation to use GitHub instead of previous hosting.
- Runtime validation of command‑line parameters against a JSON schema.

### Fixed
- Minor documentation and CI workflow adjustments.

## [0.4.0] - 2025-11-10

### Added
- **Eval Tool**: Meta-programming tool that allows the LLM to dynamically create and register new tools at runtime
  - Eval tool has access to the toolbox for enhanced capabilities
- Comprehensive test coverage with RSpec
  - Agent specs
  - Conversation specs
  - Toolbox specs

### Changed
- **Architecture Improvements**: Significant refactoring for better separation of concerns
  - Extracted Tool class to separate file (`lib/elelem/tool.rb`)
  - Extracted Toolbox class to separate file (`lib/elelem/toolbox.rb`)
  - Extracted Shell class for command execution
  - Improved tool registration through `#add_tool` method
  - Tool constants moved to Toolbox for better organization
  - Agent class simplified by delegating to Tool instances

### Fixed
- `/context` command now correctly accounts for the current mode

## [0.3.0] - 2025-11-05

### Added
- **Mode System**: Control agent capabilities with workflow modes
  - `/mode plan` - Read-only mode (grep, list, read)
  - `/mode build` - Read + Write mode (grep, list, read, patch, write)
  - `/mode verify` - Read + Execute mode (grep, list, read, execute)
  - `/mode auto` - All tools enabled
  - Each mode adapts system prompt to guide appropriate behavior
- Improved output formatting
  - Suppressed verbose thinking/reasoning output
  - Clean tool call display (e.g., `date` instead of full JSON hash)
  - Mode switch confirmation messages
  - Clear command feedback
- Design philosophy documentation in README
- Mode system documentation

### Changed
- **BREAKING**: Removed `llm-ollama` and `llm-openai` standalone executables (use main `elelem chat` command)
- **BREAKING**: Simplified architecture - consolidated all logic into Agent class
  - Removed Configuration class
  - Removed Toolbox system
  - Removed MCP client infrastructure
  - Removed Tool and Tools classes
  - Removed TUI abstraction layer (direct puts/Reline usage)
  - Removed API wrapper class
  - Removed state machine
- Improved execute tool description to guide LLM toward direct command execution
- Extracted tool definitions from long inline strings to readable private methods
- Updated README with clear philosophy and usage examples
- Reduced total codebase from 417 to 395 lines (-5%)

### Fixed
- Working directory handling for execute tool (handles empty string cwd)
- REPL EOF handling (graceful exit when input stream ends)
- Tool call formatting now shows clean, readable commands

### Removed
- `exe/llm-ollama` (359 lines)
- `exe/llm-openai` (340 lines)
- `lib/elelem/configuration.rb`
- `lib/elelem/toolbox.rb` and toolbox/* files
- `lib/elelem/mcp_client.rb`
- `lib/elelem/tool.rb` and `lib/elelem/tools.rb`
- `lib/elelem/tui.rb`
- `lib/elelem/api.rb`
- `lib/elelem/states/*` (state machine infrastructure)
- Removed ~750 lines of unused/redundant code

## [0.2.1] - 2025-10-15

### Fixed
- Added missing `exe/llm-ollama` and `exe/llm-openai` files to gemspec
- These executables were added in 0.2.0 but not included in the packaged gem

## [0.2.0] - 2025-10-15

### Added
- New `llm-ollama` executable - minimal coding agent with streaming support for Ollama
- New `llm-openai` executable - minimal coding agent for OpenAI/compatible APIs
- Memory feature for persistent context storage and retrieval
- Web fetch tool for retrieving and analyzing web content
- Streaming responses with real-time token display
- Visual "thinking" progress indicators with dots during reasoning phase

### Changed
- **BREAKING**: Migrated from custom Net::HTTP implementation to `net-llm` gem
- API client now uses `Net::Llm::Ollama` for better reliability and maintainability
- Removed direct dependencies on `net-http` and `uri` (now transitive through net-llm)
- Maps Ollama's `thinking` field to internal `reasoning` field
- Maps Ollama's `done_reason` to internal `finish_reason`
- Improved system prompt for better agent behavior
- Enhanced error handling and logging

### Fixed
- Response processing for Ollama's native message format
- Tool argument parsing to handle both string and object formats
- Safe navigation operator usage to prevent nil errors

## [0.1.2] - 2025-08-14

### Fixed
- Fixed critical bug where bash tool had nested parameters schema causing tool calls to fail with "no implicit conversion of nil into String" error

## [0.1.1] - 2025-08-12

### Fixed
- Fixed infinite loop bug after tool execution - loop now continues until assistant provides final response
- Fixed conversation history accumulating streaming chunks as separate entries - now properly combines same-role consecutive messages
- Improved state machine logging with better debug output

## [0.1.0] - 2025-08-08

- Initial release
