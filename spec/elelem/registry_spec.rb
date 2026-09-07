# frozen_string_literal: true

RSpec.describe Elelem::Registry do
  subject(:registry) { described_class.new }

  describe "#build_provider" do
    it "registers a provider factory and builds a provider from it" do
      provider = double("provider")
      registry.configure { |c| c.provider(:test) { provider } }

      expect(registry.build_provider("test")).to eq(provider)
    end

    it "accepts symbol or string names" do
      provider = double("provider")
      registry.configure { |c| c.provider("string_provider") { provider } }

      expect(registry.build_provider(:string_provider)).to eq(provider)
    end

    it "calls the factory on every build, not memoized" do
      call_count = 0
      registry.configure { |c| c.provider(:counter) { call_count += 1 } }

      registry.build_provider("counter")
      registry.build_provider("counter")

      expect(call_count).to eq(2)
    end

    it "raises a friendly error for unknown provider" do
      expect { registry.build_provider("unknown") }.to raise_error(/unknown provider/)
    end
  end

  describe "#names" do
    it "returns registered provider names" do
      registry.configure do |c|
        c.provider(:alpha) {}
        c.provider(:beta) {}
      end

      expect(registry.names).to contain_exactly("alpha", "beta")
    end
  end

  describe "#apply" do
    it "records a setup block and replays it against an agent later" do
      received = nil
      registry.configure { |c| c.setup(:probe) { |agent| received = agent } }

      agent = double("agent")
      registry.apply(agent)

      expect(received).to eq(agent)
    end
  end

  describe "#reload" do
    it "clears existing setups and toolbox/commands, then reloads plugins and reapplies" do
      plugins = instance_double(Elelem::Plugins)
      registry = described_class.new(plugins: plugins)

      calls = 0
      registry.configure { |c| c.setup(:stale) { calls += 1 } }
      allow(plugins).to receive(:load!) { registry.configure { |c| c.setup(:fresh) { calls += 1 } } }

      toolbox = instance_double(Elelem::Toolbox, clear!: nil)
      commands = instance_double(Elelem::Commands, clear!: nil)
      agent = double("agent", toolbox: toolbox, commands: commands)

      registry.reload(agent)

      expect(toolbox).to have_received(:clear!)
      expect(commands).to have_received(:clear!)
      expect(plugins).to have_received(:load!).with(force: true)
      expect(calls).to eq(1)
    end

    it "preserves provider factories across reload" do
      provider = double("provider")
      registry.configure { |c| c.provider(:test) { provider } }

      toolbox = instance_double(Elelem::Toolbox, clear!: nil)
      commands = instance_double(Elelem::Commands, clear!: nil)
      agent = double("agent", toolbox: toolbox, commands: commands)

      registry.reload(agent)

      expect(registry.build_provider("test")).to eq(provider)
    end
  end
end
