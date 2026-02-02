# frozen_string_literal: true

module Elelem
  module Providers
    def self.register(name, &factory)
      registry[name.to_s] = factory
    end

    def self.build(name)
      Plugins.load! if registry.empty?
      registry.fetch(name.to_s).call
    end

    def self.names
      registry.keys
    end

    def self.registry
      @registry ||= {}
    end
  end
end
