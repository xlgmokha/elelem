# frozen_string_literal: true

module Elelem
  class Commands
    def initialize
      @registry = {}
    end

    def register(name, description: "", &handler)
      @registry[name] = { description: description, handler: handler }
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
