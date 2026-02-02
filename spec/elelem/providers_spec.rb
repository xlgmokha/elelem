# frozen_string_literal: true

RSpec.describe Elelem::Providers do
  before do
    described_class.registry.clear
  end

  after do
    described_class.registry.clear
  end

  describe ".register" do
    it "registers a provider factory" do
      client = double("client")
      described_class.register(:test) { client }

      expect(described_class.build("test")).to eq(client)
    end

    it "accepts symbol or string names" do
      client = double("client")
      described_class.register("string_provider") { client }

      expect(described_class.build(:string_provider)).to eq(client)
    end
  end

  describe ".build" do
    it "calls the factory and returns the client" do
      call_count = 0
      described_class.register(:counter) { call_count += 1 }

      described_class.build("counter")
      described_class.build("counter")

      expect(call_count).to eq(2)
    end

    it "raises KeyError for unknown provider" do
      expect { described_class.build("unknown") }.to raise_error(KeyError)
    end
  end

  describe ".names" do
    it "returns registered provider names" do
      described_class.register(:alpha) { }
      described_class.register(:beta) { }

      expect(described_class.names).to contain_exactly("alpha", "beta")
    end
  end
end
