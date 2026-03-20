# frozen_string_literal: true

RSpec.describe Elelem do
  subject { Elelem::VERSION }

  it { is_expected.not_to be nil }
end
