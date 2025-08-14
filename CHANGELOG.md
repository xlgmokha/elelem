## [Unreleased]

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
