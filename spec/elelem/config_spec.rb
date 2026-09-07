# frozen_string_literal: true

RSpec.describe Elelem::Config do
  before do
    registry = Elelem::Registry.new
    allow(registry).to receive(:load!)
    allow(Elelem::Config).to receive(:default).and_return(registry)
  end

  it "delegates registration and building to a shared default registry" do
    provider = double("provider")
    Elelem.configure { |config| config.provider(:test) { provider } }

    expect(described_class.build_provider("test")).to eq(provider)
  end

  it "delegates setup/apply to the same shared registry" do
    received = nil
    Elelem.configure { |config| config.setup(:probe) { |agent| received = agent } }

    agent = double("agent")
    described_class.apply(agent)

    expect(received).to eq(agent)
  end
end
