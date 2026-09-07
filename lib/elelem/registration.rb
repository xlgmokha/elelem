# frozen_string_literal: true

module Elelem
  class Registration
    attr_reader :providers, :setups, :factories

    def initialize
      @providers = {}
      @setups = {}
      @factories = {}
    end

    def provider(name, &factory)
      @providers[name.to_s] = factory
      self
    end

    def setup(name, &block)
      @setups[name.to_s] = block
      self
    end

    def input(&factory)
      @factories[:input] = factory
      self
    end

    def output(&factory)
      @factories[:output] = factory
      self
    end

    def clear_setups!
      @setups.clear
    end
  end
end
