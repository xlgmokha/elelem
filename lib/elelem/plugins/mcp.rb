# frozen_string_literal: true

Elelem::Plugins.register(:mcp) do |agent|
  mcp = Elelem::MCP.new
  at_exit { mcp.close }

  Thread.new do
    mcp.tools.each do |name, tool|
      agent.toolbox.add(
        name,
        description: tool[:description],
        params: tool[:params],
        required: tool[:required],
        &tool[:fn]
      )
    end
  rescue => e
    warn "MCP failed: #{e.message}"
  end
end
