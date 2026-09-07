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
      @handler.call(args)
    end
  end
end
