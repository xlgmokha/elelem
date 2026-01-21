# frozen_string_literal: true

Elelem::Plugins.register(:mcp) do |toolbox|
  mcp = Elelem::MCP.new
  mcp.tools.each do |name, tool|
    fn = tool[:fn]
    toolbox.add(name,
      description: tool[:description],
      params: tool[:params],
      required: tool[:required],
      &fn
    )
  end
end
