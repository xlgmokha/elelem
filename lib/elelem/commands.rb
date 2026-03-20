# frozen_string_literal: true

module Elelem
  class Commands
    include Enumerable

    def initialize(registry = {})
      @registry = registry
    end

    def register(name, description: "", completions: nil, &handler)
      @registry[name] = { description: description, completions: completions, handler: handler }
    end

    def completions_for(name, partial = "")
      cmd = @registry[name]
      return [] unless cmd && cmd[:completions]

      options = cmd[:completions].respond_to?(:call) ? cmd[:completions].call : cmd[:completions]
      options.select { |o| o.start_with?(partial) }
    end

    def run(name, args = nil)
      entry = @registry[name]
      return false unless entry

      entry[:handler].arity == 0 ? entry[:handler].call : entry[:handler].call(args)
      true
    end

    def names
      @registry.keys.map { |name| "/#{name}" }
    end

    def each
      @registry.each { |name, entry| yield "/#{name}", entry[:description] }
    end

    def include?(name)
      @registry.key?(name)
    end
  end
end
