# frozen_string_literal: true

RSpec.describe Elelem::StubProvider do
  subject(:provider) { described_class.new }

  it "streams thinking, says something, and calls the first available tool" do
    events = []
    provider.fetch([{ role: "user", content: "hi" }], [{ function: { name: "noop" } }]) { |e| events << e }

    expect(events.map { |e| e[:type] }).to eq(%w[thinking saying doing])
    expect(events.last[:name]).to eq("noop")
  end

  it "says something without calling a tool once a tool result is in context" do
    events = []
    messages = [{ role: "user", content: "hi" }, { role: "tool", tool_call_id: "1", content: "{}" }]
    provider.fetch(messages, [{ function: { name: "noop" } }]) { |e| events << e }

    expect(events.map { |e| e[:type] }).to eq(%w[thinking saying])
  end

  it "says something without calling a tool when no tools are available" do
    events = []
    provider.fetch([{ role: "user", content: "hi" }], []) { |e| events << e }

    expect(events.map { |e| e[:type] }).to eq(%w[thinking saying])
  end

  it "drives a full Agent#turn to completion against a real Toolbox and NullOutput" do
    toolbox = Elelem::Toolbox.new
    toolbox.add("noop", description: "noop") { |_a| {} }
    agent = Elelem::Agent.new(provider, toolbox: toolbox)

    expect { agent.turn("hi") }.not_to raise_error
  end
end
