# frozen_string_literal: true

module Elelem
  class Tool
    attr_reader :name, :description, :params, :required, :aliases

    def initialize(name, description:, params: {}, required: [], aliases: [], &fn)
      @name = name
      @description = description
      @params = params
      @required = required
      @aliases = aliases
      @fn = fn
    end

    def call(args)
      @fn.call(args)
    end

    def to_h
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: { type: "object", properties: params, required: required }
        }
      }
    end
  end
end
