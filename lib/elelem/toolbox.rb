# frozen_string_literal: true

module Elelem
  class Toolbox
    attr_reader :tools, :hooks, :aliases

    def initialize
      @tools = {}
      @aliases = {}
      @hooks = { before: Hash.new { |h, k| h[k] = [] }, after: Hash.new { |h, k| h[k] = [] } }
    end

    def add(name, description:, params: {}, required: [], aliases: [], &fn)
      tool = Tool.new(name, description: description, params: params, required: required, aliases: aliases, &fn)
      @tools[name] = tool
      tool.aliases.each { |a| @aliases[a] = name }
    end

    def before(tool_name, &block)
      @hooks[:before][tool_name] << block
    end

    def after(tool_name, &block)
      @hooks[:after][tool_name] << block
    end

    def header(name, args)
      name = name.to_s.empty? ? "?" : name
      "\n+ #{name}(#{args})"
    end

    def run(name, args)
      name = @aliases.fetch(name, name)
      tool = tools[name]
      return { error: "unknown tool: #{name}" } unless tool

      missing = tool.required - (args&.keys || [])
      return { error: "missing required args: #{missing.join(', ')}" } if missing.any?

      @hooks[:before][name].each { |h| h.call(args) }
      result = tool.call(args)
      @hooks[:after][name].each { |h| h.call(args, result) }
      result
    rescue => e
      { error: e.message, name: name, args: args }
    end

    def to_a
      tools.values.map(&:to_h)
    end
  end
end
