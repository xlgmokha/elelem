# frozen_string_literal: true

module Elelem
  class NullOutput < Output
    def say(*, **) = nil
  end
end
