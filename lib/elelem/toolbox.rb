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

    def before(tool_name = :*, &block)
      @hooks[:before][tool_name] << block
    end

    def after(tool_name = :*, &block)
      @hooks[:after][tool_name] << block
    end

    def header(name, args, state: "+")
      tool = tool_for(name)
      color = tool ? "36" : "33"
      name = tool&.name || "#{name}?"
      "\n#{state} \e[#{color}m#{name}\e[0m(#{args})"
    end

    def run(name, args)
      tool = tool_for(name)
      return failure(error: "unknown tool: #{name}. Use 'execute' to run shell commands like rg, fd, git.", tools: to_a) unless tool

      errors = tool.validate(args)
      return failure(error: errors.join(", ")) if errors.any?

      @hooks[:before][:*].each { |h| h.call(args, tool_name: tool.name) }
      @hooks[:before][tool.name].each { |h| h.call(args) }
      result = tool.call(args)
      @hooks[:after][:*].each { |h| h.call(args, result, tool_name: tool.name) }
      @hooks[:after][tool.name].each { |h| h.call(args, result) }
      result[:error] ? failure(result) : success(result)
    rescue => e
      failure(error: e.message, name: name, args: args)
    end

    def exec(*args)
      command = args.flatten.map { |a| Shellwords.escape(a.to_s) }.join(" ")
      run("execute", { "command" => command })
    end

    def to_a
      tools.values.map(&:to_h)
    end

    private

    def tool_for(name)
      tools[@aliases.fetch(name, name)]
    end

    def success(payload)
      payload.merge(ok: true)
    end

    def failure(payload)
      payload.merge(ok: false)
    end
  end
end
