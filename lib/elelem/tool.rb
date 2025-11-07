# frozen_string_literal: true

module Elelem
  class Tool
    attr_reader :name

    def initialize(schema, &block)
      @name = schema.dig(:function, :name)
      @schema = schema
      @block = block
    end

    def call(args)
      return ArgumentError.new(args) unless valid?(args)

      @block.call(args)
    end

    def valid?(args)
      # TODO:: Use JSON Schema Validator
      true
    end

    def to_h
      @schema&.to_h
    end

    class << self
      def build(name, description, properties, required = [])
        new({
          type: "function",
          function: {
            name: name,
            description: description,
            parameters: {
              type: "object",
              properties: properties,
              required: required
            }
          }
        }) do |args|
          yield args
        end
      end
    end
  end
end
