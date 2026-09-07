# frozen_string_literal: true

module Elelem
  class Tool
    attr_reader :name, :description, :params, :required, :aliases

    def initialize(name, description:, params: {}, required: [], aliases: [], &fn)
      @name = name
      @description = description
      @params = params.freeze
      @required = required.freeze
      @aliases = aliases.freeze
      @fn = fn
      @schema_hash = { type: "object", properties: @params, required: @required }.freeze
      @schema = JSONSchemer.schema(@schema_hash)
    end

    def call(args)
      @fn.call(args)
    end

    def validate(args)
      @schema.validate(args || {}).map do |error|
        error["error"]
      end
    end

    def to_h
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: @schema_hash
        }
      }
    end

  end
end
