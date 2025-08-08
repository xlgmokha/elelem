# frozen_string_literal: true

RSpec.describe Elelem do
  it "has a version number" do
    expect(Elelem::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(Elelem.hello("World")).to eq("Hello from Rust, World!")
  end
end
