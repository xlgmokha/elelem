# MCP Integration

Elelem supports the Model Context Protocol for connecting to external tool servers.

## Configuration

Create `~/.elelem/mcp.json` (global) or `.elelem/mcp.json` (project):

```json
{
  "mcpServers": {
    "server-name": {
      "command": "path/to/server"
    }
  }
}
```

## Server Types

**Stdio** - communicates via stdin/stdout:

```json
{
  "mcpServers": {
    "myserver": {
      "command": "npx",
      "args": ["@example/mcp-server"]
    }
  }
}
```

**HTTP** - communicates via HTTP with SSE:

```json
{
  "mcpServers": {
    "myserver": {
      "type": "http",
      "url": "https://api.example.com/mcp"
    }
  }
}
```

## OAuth

HTTP servers support OAuth automatically. Elelem handles the browser flow, token storage, and refresh.

## Debugging

Logs are written to `~/.elelem/mcp.log`.
