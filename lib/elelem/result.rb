# frozen_string_literal: true

require "forwardable"

module Elelem
  class Result
    extend Forwardable
    def_delegators :@payload, :[], :each, :to_json, :to_h, :key?, :merge

    def self.success(payload)
      new(payload.merge(ok: true))
    end

    def self.failure(payload)
      new(payload.merge(ok: false))
    end

    def initialize(payload)
      @payload = payload
    end

    def ok? = !!@payload[:ok]
    def error? = !!@payload[:error]
    def error = @payload[:error]
  end
end
