# XDG Base Directory Support

As a **Linux user**, I want elelem to respect XDG Base Directory conventions, so that my configuration, data, and cache files are organized in standard locations.

## SYNOPSIS

Support `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` environment variables for file storage.

## DESCRIPTION

Currently, elelem uses `~/.elelem/` for all user-level files (permissions, plugins, prompts, MCP config). This doesn't follow the XDG Base Directory specification used by most Linux applications.

### Current Behavior

```ruby
# permissions.rb, plugins.rb, system_prompt.rb, mcp.rb
LOAD_PATHS = [
  "~/.elelem/...",
  ".elelem/..."
]
```

### Proposed Behavior

**Config** (`XDG_CONFIG_HOME` or `~/.config`):
- `permissions.json`
- `plugins/`
- `prompts/`
- `mcp.json`

**Data** (`XDG_DATA_HOME` or `~/.local/share`):
- Conversation history (future)
- MCP OAuth tokens

**Cache** (`XDG_CACHE_HOME` or `~/.cache`):
- Downloaded models (for local inference)
- MCP server logs

### Search Order (Config)

```ruby
LOAD_PATHS = [
  ".elelem",                                      # 1. Project-local (highest)
  File.join(xdg_config_home, "elelem"),           # 2. XDG location
  File.join(ENV["HOME"], ".elelem"),              # 3. Legacy (deprecated)
]
```

### Migration Path

1. **Phase 1**: Add XDG support, keep `~/.elelem` as fallback
2. **Phase 2**: Log deprecation warning when `~/.elelem` is used
3. **Phase 3**: Remove `~/.elelem` support in future major version

## SEE ALSO

* [ ] lib/elelem/permissions.rb - `LOAD_PATHS` constant
* [ ] lib/elelem/plugins.rb - `LOAD_PATHS` constant
* [ ] lib/elelem/system_prompt.rb - `LOAD_PATHS` constant
* [ ] lib/elelem/mcp.rb - hardcoded paths for config and logs
* [ ] lib/elelem/mcp/token_storage.rb - OAuth token paths
* [ ] XDG Base Directory Spec: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

## Tasks

* [ ] TBD (filled in design mode)

## Acceptance Criteria

* [ ] When `XDG_CONFIG_HOME` is set, config files load from `$XDG_CONFIG_HOME/elelem/`
* [ ] When `XDG_CONFIG_HOME` is unset, config files load from `~/.config/elelem/`
* [ ] When `XDG_DATA_HOME` is set, data files store in `$XDG_DATA_HOME/elelem/`
* [ ] When `XDG_DATA_HOME` is unset, data files store in `~/.local/share/elelem/`
* [ ] When `XDG_CACHE_HOME` is set, cache files store in `$XDG_CACHE_HOME/elelem/`
* [ ] When `XDG_CACHE_HOME` is unset, cache files store in `~/.cache/elelem/`
* [ ] Project-local `.elelem/` takes precedence over XDG locations for config
* [ ] Project-local `.elelem/` does NOT store data or cache (only config)
* [ ] Legacy `~/.elelem/` still works as fallback
* [ ] Deprecation warning logged when loading from `~/.elelem/`
* [ ] All affected files updated: permissions.rb, plugins.rb, system_prompt.rb, mcp.rb, token_storage.rb

## Implementation Notes

Consider extracting a shared module:

```ruby
module Elelem
  module Paths
    def self.config_home
      ENV["XDG_CONFIG_HOME"] || File.join(ENV["HOME"], ".config")
    end

    def self.data_home
      ENV["XDG_DATA_HOME"] || File.join(ENV["HOME"], ".local", "share")
    end

    def self.cache_home
      ENV["XDG_CACHE_HOME"] || File.join(ENV["HOME"], ".cache")
    end

    def self.config_paths
      [
        ".elelem",
        File.join(config_home, "elelem"),
        File.join(ENV["HOME"], ".elelem")  # deprecated
      ]
    end
  end
end
```
