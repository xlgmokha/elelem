# frozen_string_literal: true

module Elelem
  class SlashCommand
    attr_reader :name, :description, :completions

    def initialize(name, description = "", completions = nil, &handler)
      @name = name
      @description = description
      @completions = completions
      @handler = handler
    end

    def call(args)
      @handler.arity == 0 ? @handler.call : @handler.call(args)
    end
  end

  class Commands
    include Enumerable

    def initialize(registry = {})
      @registry = registry
    end

    def register(name, description: "", completions: nil, &handler)
      @registry[name] = SlashCommand.new(name, description, completions, &handler)
    end

    def command_for(name)
      @registry[name]
    end

    def completions_for(name, partial = "")
      cmd = command_for(name)
      return [] unless cmd && cmd.completions

      options = cmd.completions.respond_to?(:call) ? cmd.completions.call : cmd.completions
      options.select { |o| o.start_with?(partial) }
    end

    def run(name, args = nil)
      command = command_for(name)
      return false unless command

      command.call(args)
      true
    end

    def names
      @registry.keys.map { |name| "/#{name}" }
    end

    def each
      @registry.each { |name, command| yield "/#{name}", command.description }
    end

    def include?(name)
      @registry.key?(name)
    end
  end
end
