# frozen_string_literal: true

module Elelem
  class Commands
    include Enumerable

    def initialize(registry = {})
      @registry = registry
    end

    def clear!
      @registry.clear
    end

    def register(name, description: "", completions: nil, &handler)
      @registry[name] = SlashCommand.new(name, description, completions, &handler)
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

    private

    def command_for(name)
      @registry[name]
    end
  end
end
