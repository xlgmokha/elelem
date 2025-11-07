# frozen_string_literal: true

module Elelem
  class Toolbox
    attr_reader :tools

    def initialize
      @tools_by_name = {}
      @tools = { read: [], write: [], execute: [] }
      add_tool(EXEC_TOOL, :execute)
      add_tool(GREP_TOOL, :read)
      add_tool(LIST_TOOL, :read)
      add_tool(PATCH_TOOL, :write)
      add_tool(READ_TOOL, :read)
      add_tool(WRITE_TOOL, :write)
    end

    def add_tool(tool, mode)
      @tools[mode] << tool
      @tools_by_name[tool.name] = tool
    end

    def tools_for(modes)
      modes.map { |mode| tools[mode].map(&:to_h) }.flatten
    end

    def run_tool(name, args)
      @tools_by_name[name]&.call(args) || { error: "Unknown tool", name: name, args: args }
    rescue => error
      puts error.inspect
      { error: error.message, name: name, args: args }
    end
  end
end
