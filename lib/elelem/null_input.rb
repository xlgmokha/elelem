# frozen_string_literal: true

module Elelem
  class NullInput
    def ask(_prompt) = nil
    def interactive? = false
  end
end
