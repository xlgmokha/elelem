# frozen_string_literal: true

RSpec.describe Elelem::Conversation do
  subject { described_class.new }

  describe "#add" do
    it "appends messages" do
      subject.add(role: "user", content: "hello")
      subject.add(role: "assistant", content: "hi")
      expect(subject.length).to eq(2)
    end

    it "validates role" do
      expect { subject.add(role: "invalid", content: "test") }.to raise_error(ArgumentError, /invalid role/)
    end

    it "accepts user role" do
      expect { subject.add(role: "user", content: "test") }.not_to raise_error
    end

    it "accepts assistant role" do
      expect { subject.add(role: "assistant", content: "test") }.not_to raise_error
    end

    it "accepts tool role" do
      expect { subject.add(role: "tool", content: "test") }.not_to raise_error
    end
  end

  describe "#last" do
    it "returns the last message" do
      subject.add(role: "user", content: "hello")
      subject.add(role: "assistant", content: "hi")
      expect(subject.last[:content]).to eq("hi")
    end
  end

  describe "#clear!" do
    it "removes all messages" do
      subject.add(role: "user", content: "hello")
      subject.clear!
      expect(subject.length).to eq(0)
    end
  end

  describe "#to_a" do
    it "returns messages without system prompt by default" do
      subject.add(role: "user", content: "hello")
      expect(subject.to_a).to eq([{ role: "user", content: "hello" }])
    end

    it "includes system prompt when provided" do
      subject.add(role: "user", content: "hello")
      result = subject.to_a(system_prompt: "You are helpful.")
      expect(result.first).to eq({ role: "system", content: "You are helpful." })
      expect(result.last).to eq({ role: "user", content: "hello" })
    end
  end
end
