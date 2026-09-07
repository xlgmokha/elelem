# frozen_string_literal: true

module Elelem
  class Registry
    def initialize(plugins: Plugins.new)
      @registration = Registration.new
      @plugins = plugins
    end

    def configure
      yield @registration
      self
    end

    def build_provider(name)
      @plugins.load!
      @registration.providers.fetch(name.to_s) { require_gem(name) }.call
    end

    def apply(agent)
      @plugins.load!
      @registration.setups.each_value { |block| block.call(agent) }
    end

    def reload(agent)
      @registration.clear_setups!
      agent.toolbox.clear!
      agent.commands.clear!
      @plugins.load!(force: true)
      apply(agent)
    end

    def names
      @registration.providers.keys
    end

    def build_agent(provider, toolbox: Toolbox.new, input: nil, output: nil)
      commands = Commands.new
      agent = Agent.new(
        build_provider(provider),
        toolbox: toolbox,
        commands: commands,
        input: input || build_input(commands: commands),
        output: output || build_output,
      )
      apply(agent)
      agent
    end

    private

    def build_input(**opts)
      @plugins.load!
      (@registration.factories[:input] || ->(**o) { Input.new(**o) }).call(**opts)
    end

    def build_output(**opts)
      @plugins.load!
      (@registration.factories[:output] || ->(**o) { Output.new(**o) }).call(**opts)
    end

    def require_gem(name)
      require "elelem/#{name}"
      @registration.providers.fetch(name.to_s) { raise "elelem-#{name} did not register a provider named #{name.inspect}" }
    rescue LoadError
      raise "unknown provider: #{name.inspect}. Available: #{names.join(", ")}. Run: gem install elelem-#{name}"
    end
  end
end
