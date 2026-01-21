# frozen_string_literal: true

Elelem::Plugins.register(:mcp) do |toolbox|
  mcp = Elelem::MCP.new
  at_exit { mcp.close }
  mcp.tools.each do |name, tool|
    toolbox.add(name,
      description: tool[:description],
      params: tool[:params],
      required: tool[:required],
      &tool[:fn]
    )
  end
end
