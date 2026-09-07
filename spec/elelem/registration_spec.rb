# frozen_string_literal: true

RSpec.describe Elelem::Registration do
  subject(:registration) { described_class.new }

  it "chains provider/setup/output/input registration" do
    result = registration
      .provider(:test) { :client }
      .setup(:probe) { |_agent| }
      .output { :output }
      .input { :input }

    expect(result).to equal(registration)
    expect(registration.providers.keys).to eq(["test"])
    expect(registration.setups.keys).to eq(["probe"])
    expect(registration.factories[:output].call).to eq(:output)
    expect(registration.factories[:input].call).to eq(:input)
  end

  it "clears setups without clearing providers" do
    registration.provider(:test) { :client }
    registration.setup(:probe) { |_agent| }

    registration.clear_setups!

    expect(registration.providers.keys).to eq(["test"])
    expect(registration.setups).to be_empty
  end
end
