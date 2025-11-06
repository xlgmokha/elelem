# frozen_string_literal: true

module Elelem
  class Tool
    def initialize(schema, &block)
      @schema = schema
      @block = block
    end

    def call(args)
      @block.call(args)
    end

    def to_h
      @schema
    end
  end
end
