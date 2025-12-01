## [Unreleased]

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

