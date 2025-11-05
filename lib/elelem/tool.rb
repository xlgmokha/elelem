# frozen_string_literal: true

module Elelem
  class Tool
    attr_reader :name, :description, :parameters

    def initialize(name, description, parameters)
      @name = name
      @description = description
      @parameters = parameters
    end

    def valid?(args)
      JSON::Validator.validate(parameters, args, insert_defaults: true)
    end

    def to_h
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: parameters
        }
      }
    end
  end
end
