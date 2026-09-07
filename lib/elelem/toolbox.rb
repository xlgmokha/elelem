# frozen_string_literal: true

module Elelem
  class Toolbox
    attr_reader :tools, :hooks, :aliases

    def initialize
      @tools = {}
      @aliases = {}
      @hooks = { before: Hash.new { |h, k| h[k] = [] }, after: Hash.new { |h, k| h[k] = [] } }
    end

    def clear!
      @tools.clear
      @aliases.clear
      @hooks[:before].clear
      @hooks[:after].clear
    end

    def add(name, description:, params: {}, required: [], aliases: [], &fn)
      tool = Tool.new(name, description: description, params: params, required: required, aliases: aliases, &fn)
      @tools[name] = tool
      tool.aliases.each { |a| @aliases[a] = name }
    end

    def before(tool_name = :*, &block)
      @hooks[:before][tool_name] << block
    end

    def after(tool_name = :*, &block)
      @hooks[:after][tool_name] << block
    end

    def tool_for(name)
      tools.fetch(@aliases.fetch(name, name)) { NullTool.new(name, available: tools.keys) }
    end

    def run(name, args)
      tool = tool_for(name)
      errors = tool.validate(args)
      return Result.failure(error: errors.join(", ")) if errors.any?

      result = dispatch(tool, args)
      result[:error] ? Result.failure(result) : Result.success(result)
    rescue => e
      Elelem.logger.warn("toolbox: #{e.message}\n#{e.backtrace.join("\n")}")
      Result.failure(error: e.message, name: name, args: args)
    end

    def to_a
      tools.values.map(&:to_h)
    end

    private

    def dispatch(tool, args)
      @hooks[:before][:*].each { |h| h.call(args, tool_name: tool.name) }
      @hooks[:before][tool.name].each { |h| h.call(args) }
      result = tool.call(args)
      @hooks[:after][:*].each { |h| h.call(args, result, tool_name: tool.name) }
      @hooks[:after][tool.name].each { |h| h.call(args, result) }
      result
    end
  end
end
