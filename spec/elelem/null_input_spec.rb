# frozen_string_literal: true

require "spec_helper"

RSpec.describe Elelem::NullInput do
  subject(:input) { described_class.new }

  it "returns nil for ask" do
    expect(input.ask("> ")).to be_nil
  end

  it "is not interactive" do
    expect(input.interactive?).to eq(false)
  end
end
