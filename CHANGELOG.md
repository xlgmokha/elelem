## [Unreleased]

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
