# frozen_string_literal: true

RSpec.describe Elelem::Commands do
  subject { described_class.new }

  describe "#register" do
    it "registers a command with handler" do
      called = false
      subject.register("test") { called = true }
      subject.run("test")
      expect(called).to be true
    end

    it "stores description" do
      subject.register("test", description: "Test command") { }
      expect(subject.include?("test")).to be true
    end
  end

  describe "#run" do
    it "returns true when command exists" do
      subject.register("test") { }
      expect(subject.run("test")).to be true
    end

    it "returns false when command does not exist" do
      expect(subject.run("nonexistent")).to be false
    end
  end

  describe "#names" do
    it "returns command names with slash prefix" do
      subject.register("exit") { }
      subject.register("help") { }
      expect(subject.names).to contain_exactly("/exit", "/help")
    end
  end

  describe "#include?" do
    it "returns true for registered commands" do
      subject.register("test") { }
      expect(subject.include?("test")).to be true
    end

    it "returns false for unregistered commands" do
      expect(subject.include?("test")).to be false
    end
  end
end
